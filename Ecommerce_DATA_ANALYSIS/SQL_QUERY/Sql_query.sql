
USE ecommerce_portfolio;

-- Check all tables
SELECT 
    'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;


-- Q1: Top 5 Customers by Revenue with Running Total

with customers_revenue as(
	SELECT 
		c.customer_id,
		c.customer_name,
		c.segment,
		sum(oi.sales) as total_revenue,
		sum(oi.profit) as total_profit,
		count(DISTINCT o.order_id) as total_ordes
	FROM customers c
	join orders o 
	on o.customer_id=c.customer_id
	join order_items oi
	on oi.order_id=o.order_id
	GROUP BY c.customer_id,c.customer_name,c.segment),
ranked_customer as(
	select *,
		RANK() over(order by total_revenue desc) as revenue_rank,
		SUM(total_revenue) OVER(
			order by total_revenue desc 
			ROWS BETWEEN UNBOUNDED PRECEDING and CURRENT ROW
		) as running_revenue
	 from customers_revenue
	)
SELECT 
	customer_id,
    customer_name,
    segment,
    round(total_revenue,2) as revenue,
    round(total_profit,2) as profit,
    round(running_revenue,2) as cummulative_revenue,
    concat(
		round(running_revenue/(select sum(total_revenue) from customers_revenue)*100,2),'%'
    ) as revenue_contribution
from ranked_customer
where revenue_rank<=5;
    

-- Q2: Month-over-Month Sales Growth
WITH monthly_sales as(
	SELECT 
		date_format(o.order_date,'%Y-%m') as month,
		sum(oi.sales) as sales,
		sum(oi.profit) as profit,
		count(DISTINCT o.order_id) as orders_count
	FROM customers c
	join orders o 
	on o.customer_id=c.customer_id
	join order_items oi
	on oi.order_id=o.order_id
	GROUP BY date_format(o.order_date,'%Y-%m')
    ),
growth_table as (
	SELECT 
		month,
		round(sales,2) as cm_sales,
		LAG(round(sales,2)) over(order by month) as pm_sales,
		sales-LAG(round(sales,2)) over(order by month) as sales_growth
	from monthly_sales
)
SELECT 
	month,
    cm_sales,
    pm_sales,
    sales_growth,
    concat(
		round(sales_growth*100/pm_sales,2),'%'
    )as growth_percentage 
from growth_table;
    
-- Q3: Product Performance Analysis 
WITH product_metrics as(
	select 
		p.product_id,
		p.product_name,
		p.category,
		p.sub_category,
		sum(oi.sales) as total_sales,
		sum(oi.profit) as total_profit,
		sum(oi.quantity) as total_quantity,
		count(DISTINCT oi.order_id) as order_count
	FROM products p
	JOIN order_items oi
	on p.product_id=oi.product_id
	GROUP BY p.product_id,p.product_name,p.category,p.sub_category
),
cat_avg as(
	SElECT 
		category,
		avg(total_profit) as avg_category_profit
	from product_metrics
	GROUP BY category)
select
	pm.product_name,
    pm.category,
    pm.sub_category,
    pm.total_sales as revenue,
    pm.total_profit as profit,
    pm.total_quantity as units_sold,
    round((pm.total_profit/pm.total_sales) *100,2) as profit_margin,
    CASE
		WHEN pm.total_profit>ca.avg_category_profit THEN 'Above Average'
        WHEN pm.total_profit<ca.avg_category_profit THEN 'Below Average'
        ElSE 'Average'
	END as performance_status,
    DENSE_RANK() OVER(PARTITION BY pm.category ORDER BY pm.total_profit desc) as cat_rank
from product_metrics pm
join cat_avg ca 
on ca.category=pm.category
where pm.total_sales>=(
	SELECT avg(total_sales) from product_metrics
)
ORDER BY pm.total_profit desc
limit 20;


-- Q4: Customer Segmentation with RFM Analysis (Recency, Frequency, Monetary)
With rfm_calc as (
	SELECT 
		c.customer_id,
		c.customer_name,
		c.segment,
		datediff((SELECT max(order_date) from orders),max(o.order_date)) as recency,
		count(DISTINCT o.order_id) as frequency,
		sum(oi.sales) as monetary
	from customers c
	JOIN orders o
	on o.customer_id=c.customer_id
	join order_items oi
	on o.order_id=oi.order_id
	GROUP BY c.customer_id,c.customer_name,c.segment),
rfm_score as (
	SELECT 
		*,
		NTILE(5) OVER(ORDER BY recency desc) as r_score,
		NTILE(5) OVER(ORDER BY frequency ASC) as f_score,
		NTILE(5) OVER(ORDER BY monetary ASC) as m_score
	from rfm_calc
)
SELECT
	*,
    (r_score+f_score+m_score) as rfm_total,
	CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END as customer_segment
from rfm_score
ORDER BY rfm_total desc;

-- Q5.Which regions are doing better than average, and inside those regions, how is each state performing?
WITH base_data as(
SELECT
	c.customer_id,
	c.region,
	c.state,
	o.order_id,
	oi.product_id,
	oi.sales,
	oi.profit
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
JOIN order_items oi 
ON o.order_id = oi.order_id
),
region_revenue as (
	SELECT
		region,
		SUM(sales) as region_revenue
	from base_data
	GROUP BY region
),
avg_region_revenue as
(	
	SELECT 
		avg(region_revenue) as avg_region_revenue
	from region_revenue
),
region_matrics as (
	SELECT
		region,
		state,
		count(DISTINCT customer_id) as total_customers,
		count(DISTINCT order_id) as total_orders,
		sum(sales) as total_revenue,
		sum(profit) as total_profit,
		avg(sales) as avg_order_value
	from base_data
	GROUP BY region,state
    ),
top_product_by_region as(
	SELECT 
		bd.region,
		p.product_name,
		sum(bd.sales) as sales,
		RANK() OVER(PARTITION BY bd.region ORDER BY sum(bd.sales) desc) as rn
	from base_data bd
	join products p
	on bd.product_id=p.product_id
	GROUP BY bd.region,p.product_name
)
SELECT 
	rm.region,
    rr.region_revenue,
    rm.state,
    rm.total_customers,
    rm.total_orders,
    rm.total_revenue,
    rm.total_profit,
    round((rm.total_profit/rm.total_revenue)*100,2) as profit_margin,
    tp.product_name as top_selling_product,
    RANK() OVER (PARTITION BY region Order BY rm.total_revenue desc) AS state_rank
from region_matrics rm
join region_revenue rr
on rm.region=rr.region
join top_product_by_region tp
on tp.region=rm.region 
and tp.rn=1
WHERE rr.region_revenue>(SELECT avg_region_revenue from avg_region_revenue)
ORDER BY rr.region_revenue desc;
    
-- Q6: Cohort Analysis - Customer Retention
WITH first_order as(
	SELECT 
		c.customer_id,
		min(o.order_date) as first_order_date
	FROM customers c
	JOIN orders o 
	on c.customer_id=o.customer_id
	GROUP BY c.customer_id
),
customers_order as(
	SELECT
		o.customer_id,
		date_format(fo.first_order_date,'%Y-%m-01') as cohort_month,
		date_format(o.order_date,'%Y-%m-01') as order_month
	FROM orders o
	join first_order fo
	on fo.customer_id=o.customer_id),
cohort_index as (
SELECT 
	customer_id,
    cohort_month,
    order_month,
        (
            YEAR(order_month) * 12 + MONTH(order_month)
        ) -
        (
            YEAR(cohort_month) * 12 + MONTH(cohort_month)
        ) AS month_number
from customers_order
),
cohort_counts as
(
	SELECT 
		cohort_month,
		month_number,
		count(DISTINCT customer_id) as active_customers
	FROM cohort_index
	GROUP BY cohort_month,month_number),
cohort_size as 
(
	SELECT
		cohort_month,
		count(DISTINCT customer_id) as cohort_users
	From cohort_index
	where month_number=0
	GROUP BY cohort_month
)
SELECT
	cc.cohort_month,
    cc.month_number,
    cc.active_customers,
    cs.cohort_users,
    round((cc.active_customers*100)/cs.cohort_users,2) as retention_rate
From cohort_counts cc
JOIN cohort_size cs
on cc.cohort_month=cs.cohort_month
ORDER BY cc.cohort_month,cc.month_number
;












