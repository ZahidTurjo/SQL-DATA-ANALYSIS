-- Top 3 outlets by cusine type without using limit and top function

with cte as (select Cuisine,Restaurant_id,
count(*) as order_count
from orders
group by Cuisine,Restaurant_id)
select * from (select *,
row_number() over(partition by Cuisine order by order_count desc) as rn
from cte) a
where a.rn=1;

-- 2.find the daily new customer count from the launch date(everyday how many new customers are we aquiring)
with cte as(
	select Customer_code,
	min(date(Placed_at)) as first_date
	from orders
	group by Customer_code)
select first_date ,
count(*) as customer_count
from cte
group by first_date;

-- 3 3.Count All the users who were aquired in jan and only place
-- one order in jan and did not place any other order
SELECT Customer_code, count(*) as orders
from orders
where MONTH(Placed_at)=1 and YEAR(Placed_at)=2025
and Customer_code not in(
	select distinct Customer_code
	from orders 
	where not (MONTH(Placed_at)=1 and YEAR(Placed_at)=2025)
    )
group by Customer_code 
having count(*)=1;

-- 4 List all customers who made their first order using a promo code
--  and have not placed anyorder in the last 7 days 
--  (based on the latest date available in the data).
with customer_orders as(
	select Customer_code,
	min(Placed_at) as first_order_date,
	max(Placed_at) as last_order_date
	from orders
	group by Customer_code),
max_date as(
	select max(Placed_at) as ref_date
	from orders
)
select Customer_code,Date(first_order_date) as first_order_date,
Date(last_order_date) as last_order_date,
Promo_code_Name,
datediff(max_date.ref_date,a.last_order_date) from (
	select c.Customer_code,first_order_date,
	last_order_date,o.Promo_code_Name
	from orders o
	join customer_orders c
	on o.Customer_code=c.Customer_code
	and o.Placed_at=c.first_order_date
	where o.Promo_code_name is Not NULL)a
    cross join max_date
where datediff(max_date.ref_date,a.last_order_date)>7;

-- 5 Growth Team is planning to create a trigger that will target
-- customers after their every 3rd order with a personalized communication
-- and they have asked you to create aquery for this

with ranked_orders as (select *,
row_number() over(partition by Customer_code order by placed_at) as order_numbers
from orders)
select * from ranked_orders
where order_numbers%3=0 ;

-- 6. list customers who placed more than 1 order and all their orders on a promo only
select Customer_code,count(*) as total_orders ,
count(Promo_code_name) as orders_on_promo
from orders
group by Customer_code
having count(*)>1 and count(Promo_code_name)=count(*) ;

-- 7. List customers were organically aquired in jann 2025.(Placed Their First order without Promocode)
select * from(
	select *,
	row_number() over(partition by Customer_code order by placed_at) as rn
	from orders
) a
where a.rn=1 and
 a.Promo_code_Name is NUll
 and Month(a.Placed_at)=1;

-- 8. What percent of customers were organically aquired in jann 2025.(Placed Their First order without Promocode)
select 
round(100*sum(case 
when Promo_code_name is NUll then 1
else 0 end)/count(*),2)
as organic_acquisition_percent 
from(
	select *,
	row_number() over(partition by Customer_code order by placed_at) as rn
	from orders
) a
where a.rn=1
 and Month(a.Placed_at)=1;
