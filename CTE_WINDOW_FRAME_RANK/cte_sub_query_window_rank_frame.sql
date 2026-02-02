Use advanced_sql_db;

-- Compare each employee's salary to their department's average salary

select first_name,e.department_id,
e.salary,d.department_name,
avg(salary) over(partition by department_id order by department_id) as avg_dept_sal,
e.salary-avg(salary) over(partition by department_id order by department_id) as variance
from employees e
join departments d
on e.department_id=d.department_id;

-- using CTE
with cte as(SELECT 
    department_id, AVG(salary) AS avg_dept_salary
FROM
    employees
GROUP BY department_id)
SELECT 
    e.first_name,
    e.department_id,
    d.department_name,
    c.avg_dept_salary,
    e.salary - c.avg_dept_salary AS variance
FROM
    employees e
        JOIN
    departments d ON e.department_id = d.department_id
        JOIN
    cte c ON c.department_id = e.department_id;

-- Month Over Month Growth using Lag()
select a.*,
a.delta*100/a.pm_sales as mom from
(select 
	year(o.order_date) as sales_year,
	month(o.order_date) as sales_month,
	sum((oi.unit_price*oi.quantity)*(1-oi.discount)) as cm_sales,
	lag(sum((oi.unit_price*oi.quantity)*(1-oi.discount)))
	over(order by year(o.order_date),month(o.order_date)) as pm_sales,
    sum((oi.unit_price*oi.quantity)*(1-oi.discount))-
	lag(sum((oi.unit_price*oi.quantity)*(1-oi.discount)))
	over(order by year(o.order_date),month(o.order_date)) as delta
from orders o
join order_items oi
on o.order_id=oi.order_id
group by 1,2
order by 1,2) a;

-- Calculate Running Total/Running Sum
select 
Year(o.order_date) as sales_year,
month(o.order_date) as sales_month ,
(sum((oi.unit_price*oi.quantity)*(1-oi.discount))) as cm_sales,
sum(sum((oi.unit_price*oi.quantity)*(1-oi.discount)))
over(order by year(o.order_date),month(o.order_date)
rows between unbounded preceding and current row
) as run_total
from orders o
left join order_items oi
on o.order_id=oi.order_id
group by 1,2
order by 1,2;

--  Calculate 3 months moving average

select 
Year(o.order_date) as sales_year,
month(o.order_date) as sales_month ,
(sum((oi.unit_price*oi.quantity)*(1-oi.discount))) as cm_sales,
avg(sum((oi.unit_price*oi.quantity)*(1-oi.discount)))
over(order by year(o.order_date),month(o.order_date)
rows between 2 preceding and current row
) as moving_avg
from orders o
left join order_items oi
on o.order_id=oi.order_id
group by 1,2
order by 1,2;


-- Salary Rank of each employee on his/her department

select concat(first_name,' ',last_name) ,
department_id,salary,
rank() over(partition by department_id order by salary desc) as rank_using_rank,
dense_rank() over(partition by department_id order by salary desc) as rank_using_dense_rank,
row_number() over(partition by department_id order by salary desc) as rn
from employees;















































