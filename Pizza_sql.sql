create database pizza_db;

use pizza_db;

select * 
from orders;

select *
from order_details;

select *
from pizzas;

select *
from pizza_types;

-- Chapter 1

-- Most ordered pizza
select pizza_type_id, sum(quantity) as count_pizza
from order_details as a
join pizzas as b 
on a.pizza_id = b.pizza_id
group by pizza_type_id
order by count_pizza desc;

-- High revenue pizza
select b.pizza_type_id, sum(a.quantity * b.price) over (partition by b.pizza_type_id) as total_pizza_price
from order_details as a
join pizzas as b 
on a.pizza_id = b.pizza_id
order by total_pizza_price desc
limit 1;

--  Or using
with cte as (
     select a.pizza_id, b.pizza_type_id, a.quantity, b.price
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
 ),
 cte1 as (
     SELECT pizza_type_id, SUM(quantity * price) AS total_price
     FROM cte
     GROUP BY pizza_type_id
  )
     select *
     from cte1
	 order by total_price desc
     limit 1;

-- Sales trend over time(quantity of orders per months)
WITH cte AS (
    SELECT 
        a.order_id, 
        a.pizza_id, 
        a.quantity, 
        STR_TO_DATE(b.date, '%Y-%m-%d') AS order_date_converted
    FROM order_details AS a
    JOIN orders AS b ON a.order_id = b.order_id
),
cte1 AS (
    SELECT 
        DATE_FORMAT(order_date_converted, '%Y-%m') AS order_month,
        SUM(quantity) AS total_quantity
    FROM cte 
    GROUP BY DATE_FORMAT(order_date_converted, '%Y-%m')
)
    SELECT *
    FROM cte1
    ORDER BY order_month;

-- Average order per day
WITH cte AS (
    SELECT 
        a.order_id, 
        a.pizza_id, 
        a.quantity, 
        b.date AS order_date_converted
    FROM order_details AS a
    JOIN orders AS b ON a.order_id = b.order_id
),
cte1 as (
    select sum(quantity) as total_quantity, count(distinct order_date_converted) as count_order_date
    from cte
    ),
cte2 as (
    select total_quantity/count_order_date as avg_order_per_day
    from cte1
    )
    SELECT *
    FROM cte2;

-- Peak order time
WITH cte AS (
     SELECT 
        a.order_id, 
        a.pizza_id, 
        a.quantity,
        str_to_date(b.time, '%H:%i:%s') as time_conversion
     FROM order_details AS a
     JOIN orders AS b ON a.order_id = b.order_id
),
cte1 as (
     select date_format(time_conversion, '%H'), count(distinct order_id)
     from cte
     group by date_format(time_conversion, '%H')
     order by count(distinct order_id) desc
     )
     select *
     from cte1;

-- or using
select *
        , sum(hourly_orders) over () as total_orders
		, hourly_orders *100.00/ sum(hourly_orders) over () as contri_orders
from (
select hour(time) as hr, count(distinct order_id) as hourly_orders
from orders
group by hour(time)
) as a;

-- Chapter 2

-- Total orders
select count(order_id) as total_orders
from order_details;

-- Total revenue
with cte as (
     select a.pizza_id, a.quantity, b.price, (a.quantity * b.price) as pizza_price
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
     ),
cte1 as (
     select sum(pizza_price) as total_revenue
     from cte
     )
     select * 
     from cte1;
     
-- Highest price pizza
select max(price) as highest_price
from pizzas;

-- Most common pizza size
with cte as (
     select a.pizza_id, a.quantity, b.size
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
),
cte1 as (
     select size, count(quantity)
     from cte
     group by size
     )
     select *
     from cte1;
     
-- Chapter 3

-- 5 Highest order_id based on pizza quantity
select pt.name, sum(od.quantity) as total_quantity
from pizza_types as pt 
left join pizzas as p on p.pizza_type_id = pt.pizza_type_id
left join order_details as od on od.pizza_id = p.pizza_id
group by pt.name
order by total_quantity desc
limit 5;

-- 3 Highest order_id based on pizza price
with cte as (
     select a.order_id, a.pizza_id, a.quantity, b.price, (a.quantity * b.price) as pizza_price
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
     ),
cte1 as (
     select order_id, sum(pizza_price)
     from cte 
     group by order_id
     order by sum(pizza_price) desc
     limit 3
     )
     select *
     from cte1;
     
-- Chapter 4

-- Percentage contribution of each pizza type to total revenue
with cet as (
	 select a.order_id, a.pizza_id,b.pizza_type_id, a.quantity, b.price, (a.quantity * b.price) as pizza_price
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
),
cet1 as (
     select pizza_type_id, (sum(pizza_price) / (select sum(pizza_price) from cet))*100 as percent_contri_per_type
     from cet
     group by pizza_type_id
     order by percent_contri_per_type desc
     )
     select *
     from cet1;
     
-- cumulative revenue generated over time 
with cte as (
     select b.pizza_type_id, a.order_id, a.pizza_id, (a.quantity * b.price) as pizza_price
     from order_details as a 
     join pizzas as b
     on a.pizza_id = b.pizza_id
),
cte1 as (
     select *,sum(pizza_price) over (order by order_id rows between unbounded preceding and current row) as num
     from cte
)
    select * 
    from cte1
    order by num asc;

-- Top 3 most ordered pizza types based on revenue for each pizza category
with cte as (
     select a.order_id, a.pizza_id,b.pizza_type_id, a.quantity, b.price, c.category, (a.quantity * b.price) as pizza_price
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
     join pizza_types as c
     on c.pizza_type_id = b.pizza_type_id
),
cte1 as ( 
     select category, sum(pizza_price)
     from cte 
     group by category
     order by sum(pizza_price) desc
     )
     select *
     from cte1
     limit 3;
     
-- Chapter 5

-- Join the necessary tables to find the total quantity of each pizza category ordered.
select * from order_details;
select * from pizza_types;
select * from pizzas;

select pt.category, sum(od.quantity) as cat_quantity
from pizza_types as pt
left join pizzas as p on p.pizza_type_id = pt.pizza_type_id
left join order_details as od on od.pizza_id = p.pizza_id
group by pt.category;


-- Join relevant tables to find the category-wise distribution of pizzas.
with final as (
select pt.category, sum(od.quantity) as cat_quantity
from pizza_types as pt
left join pizzas as p on p.pizza_type_id = pt.pizza_type_id
left join order_details as od on od.pizza_id = p.pizza_id
group by pt.category
)

select *
, cat_quantity *100.00/ sum(cat_quantity) over () as distribution
from final;


-- Group the orders by the date and calculate the average number of pizzas ordered per day.

select avg(total_quantity)
from (
select date, sum(od.quantity) as total_quantity
from orders as o
left join order_details as od on od.order_id = o.order_id
group by date
) as a;

