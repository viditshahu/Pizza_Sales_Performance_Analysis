create database pizza_db;

use pizza_db;

select *
from orders;

select  *
from order_details;

select *
from pizzas;

select *
from pizza_types;

-- Chapter 1

-- Most ordered pizza name
select c.name as pizza_name, sum(a.quantity) as count_pizza
from order_details as a
join pizzas as b 
on a.pizza_id = b.pizza_id
join pizza_types as c
on c.pizza_type_id = b.pizza_type_id
group by c.name
order by sum(a.quantity) desc
limit 5;

-- High revenue pizza name
select c.name as pizza_name, sum(a.quantity * b.price) as total_pizza_price
from order_details as a
join pizzas as b 
on a.pizza_id = b.pizza_id
join pizza_types as c
on c.pizza_type_id = b.pizza_type_id
group by c.name
order by sum(a.quantity * b.price) desc
limit 1;

-- Percentage of sales trend over time(quantity of orders per months)
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
        ROUND(SUM(quantity)*100.0/(select sum(quantity) from order_details),2) AS percent_monthly_quantity_contribution
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

-- Peak order time with percentage contribution
select *, round(hourly_orders * 100.00 / (select count(order_id) from orders), 2)  as hourly_percent_orders_contribution
from (
select hour(time) as hr, count(order_id) as hourly_orders
from orders
group by hour(time)
) as subquery
order by hourly_percent_orders_contribution desc;

-- Chapter 2

-- Total orders
select count(order_id) as total_orders
from orders;

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
select b.name, a.price as highest_price
from pizzas a
join pizza_types b
on a.pizza_type_id = b.pizza_type_id
where a.price = (
    SELECT MAX(price) 
    FROM pizzas
);


-- Most common pizza size
with cte as (
     select b.size, a.quantity
     from order_details as a
     join pizzas as b
     on a.pizza_id = b.pizza_id
)
     select size, sum(quantity) as total_quantity
     from cte
     group by size 
     order by  total_quantity desc;
     
-- Chapter 3

-- 5 Highest pizza name based on pizza quantity
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

-- Percentage contribution of each pizza category to total revenue
with cet as (
	 select c.category, a.quantity, b.price, (a.quantity * b.price) as pizza_price
     from order_details as a
	 join pizzas as b
     on a.pizza_id = b.pizza_id
     join pizza_types as c
     on b.pizza_type_id = c.pizza_type_id
),
cet1 as (
     select category, sum(pizza_price), round(sum(pizza_price)*100 / (select sum(pizza_price) from cet), 2) as percent_contri_per_category
     from cet
     group by category
     order by percent_contri_per_category desc
     )
     select *
     from cet1;
     
-- cumulative revenue generated over time 
with cte as (
     select b.date, sum(a.quantity * c.price) as pizza_price
     from order_details as a 
     join orders as b
     on a.order_id = b.order_id
     join pizzas as c
     on a.pizza_id = c.pizza_id
     group by b.date
)
     select date, sum(pizza_price) over (order by date rows between unbounded preceding and current row) as cumulative_revenue
     from cte;
     
-- Chapter 5

-- Join relevant tables to find the category-wise distribution of pizzas quantity
with final as (
select pt.category, sum(od.quantity) as category_quantity_total
from pizza_types as pt
left join pizzas as p 
on p.pizza_type_id = pt.pizza_type_id
left join order_details as od 
on od.pizza_id = p.pizza_id
group by pt.category
)
select *, category_quantity_total * 100.00 / sum(category_quantity_total) over () as category_quantity_distribution
from final;
