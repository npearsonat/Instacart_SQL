--Top Products by Department and Aisle
--Find the top 3 products per department or aisle using RANK() or ROW_NUMBER().
--Show order count, reorder rate, and compare which aisles drive loyalty.

select department,department_id, product_name, product_id, product_count
from(
select
	p.department_id,
	p.product_name,
	p.product_id,
	d.department,
	count(p.product_id) as product_count,
	rank() over (partition by d.department order by count(*) desc) as rnk
from departments d
join products p on p.department_id = d.department_id
join order_products__prior op on p.product_id = op.product_id
group by p.product_id, d.department, p.product_name, p.department_id
) as ranked
where rnk <= 3
order by department
-- by aisle
select aisle,aisle_id, product_name, product_id, product_count
from(
select
	p.aisle_id,
	p.product_name,
	p.product_id,
	a.aisle,
	count(p.product_id) as product_count,
	rank() over (partition by a.aisle order by count(*) desc) as rnk
from aisles a
join products p on p.aisle_id = a.aisle_id
join order_products__prior op on p.product_id = op.product_id
group by p.product_id, a.aisle, p.product_name, p.aisle_id
) as ranked
where rnk <= 3
order by aisle

-- Popular products by time of day
select*
from(
select
	o.order_hour_of_day,
	p.product_name,
	op.product_id,
	count(op.order_id) as product_count,
	row_number() over (partition by o.order_hour_of_day order by count(op.order_id) desc) as rn
from order_products__prior op
join orders o on o.order_id = op.order_id
join products p on op.product_id = p.product_id
group by o.order_hour_of_day, op.product_id, p.product_name) as ranked
where rn = 1
order by order_hour_of_day asc

-- Most reordered products
select *
from (
    select 
		p.product_name,
	    p.product_id,
        p.department_id,
        count(*) as total_orders,
        sum(op.reordered) as total_reorders,
        sum(op.reordered)*1.0/count(*) as reorder_rate
    from order_products__prior op
    join products p on op.product_id = p.product_id
    group by p.department_id, p.product_id, p.product_name
) as t
where total_reorders >= 50
order by reorder_rate desc;
---- products bought together
select 
    p1.product_name as product_a_name,
    p2.product_name as product_b_name,
    count(*) as times_bought_together
from order_products__prior op1
join order_products__prior op2 
    on op1.order_id = op2.order_id and op1.product_id < op2.product_id
join products p1 on op1.product_id = p1.product_id
join products p2 on op2.product_id = p2.product_id
group by p1.product_name, p2.product_name
order by times_bought_together desc;
--- Orders per hour
select 
    order_hour_of_day,
    count(*) as total_orders
from orders
group by order_hour_of_day
order by order_hour_of_day asc;
---- Average order size vs days since last order
select 
    o.days_since_prior_order,
    avg(op_count.product_count) as avg_order_size
from orders o
join (
    select order_id, count(product_id) as product_count
    from order_products__prior
    group by order_id
) op_count on o.order_id = op_count.order_id
group by o.days_since_prior_order
order by o.days_since_prior_order;
--- Which products are added when?
select add_to_cart_order, product_name, product_id, total_times_added
from (
    select 
        op.add_to_cart_order,
        p.product_name,
        op.product_id,
        count(*) as total_times_added,
        row_number() over (
            partition by op.add_to_cart_order
            order by count(*) desc
        ) as rn
    from order_products__prior op
    join products p on op.product_id = p.product_id
    group by op.add_to_cart_order, op.product_id, p.product_name
) ranked
where rn = 1
order by add_to_cart_order;
-- Proportion of first time vs reordered items
SELECT
    CASE WHEN reordered = 1 THEN 'Reordered'
         ELSE 'First Time' END AS order_type,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_products__prior), 2) AS percentage
FROM order_products__prior
GROUP BY CASE WHEN reordered = 1 THEN 'Reordered' ELSE 'First Time' END;
--- create 100 product+ users
SELECT user_id
INTO #users_25plus
FROM orders
GROUP BY user_id
HAVING COUNT(order_id) > 25;
--- Average days since prior order based on order total orders
WITH user_order_counts AS (
    SELECT
        user_id,
        COUNT(order_id) AS total_orders,
        AVG(days_since_prior_order) AS avg_days_since
    FROM orders
    WHERE days_since_prior_order IS NOT NULL
    GROUP BY user_id
),
binned AS (
    SELECT
        user_id,
        avg_days_since,
        CASE
            WHEN total_orders < 10 THEN '0–9'
            WHEN total_orders BETWEEN 10 AND 19 THEN '10–19'
            WHEN total_orders BETWEEN 20 AND 29 THEN '20–29'
            WHEN total_orders BETWEEN 30 AND 39 THEN '30–39'
            WHEN total_orders BETWEEN 40 AND 49 THEN '40–49'
            WHEN total_orders BETWEEN 50 AND 59 THEN '50–59'
            WHEN total_orders BETWEEN 60 AND 69 THEN '60–69'
            WHEN total_orders BETWEEN 70 AND 79 THEN '70–79'
            WHEN total_orders BETWEEN 80 AND 89 THEN '80–89'
            WHEN total_orders BETWEEN 90 AND 99 THEN '90–99'
            ELSE '100+'
        END AS order_group
    FROM user_order_counts
)
SELECT
    order_group,
    ROUND(AVG(avg_days_since), 2) AS avg_days_since_prior,
    COUNT(DISTINCT user_id) AS users_in_group
FROM binned
GROUP BY order_group
ORDER BY
    CASE 
        WHEN order_group = '0–9' THEN 1
        WHEN order_group = '10–19' THEN 2
        WHEN order_group = '20–29' THEN 3
        WHEN order_group = '30–39' THEN 4
        WHEN order_group = '40–49' THEN 5
        WHEN order_group = '50–59' THEN 6
        WHEN order_group = '60–69' THEN 7
        WHEN order_group = '70–79' THEN 8
        WHEN order_group = '80–89' THEN 9
        WHEN order_group = '90–99' THEN 10
    END;
---- Users with high proportion of department items
WITH user_dept_counts AS (
    SELECT
        o.user_id,
        p.department_id,
        COUNT(*) AS items_in_dept
    FROM orders o
    JOIN order_products__prior opp ON o.order_id = opp.order_id
    JOIN products p ON opp.product_id = p.product_id
    GROUP BY o.user_id, p.department_id
),
user_total_counts AS (
    SELECT
        user_id,
        SUM(items_in_dept) AS total_items
    FROM user_dept_counts
    GROUP BY user_id
),
user_dept_ratio AS (
    SELECT
        ud.user_id,
        ud.department_id,
        CAST(ud.items_in_dept AS FLOAT) / utc.total_items AS dept_ratio
    FROM user_dept_counts ud
    JOIN user_total_counts utc ON ud.user_id = utc.user_id
),
total_users AS (
    SELECT COUNT(DISTINCT user_id) AS total_users FROM orders
)
SELECT
    d.department AS department_name,
    COUNT(udr.user_id) AS num_users,
    ROUND(100.0 * COUNT(udr.user_id) / tu.total_users, 2) AS percent_of_total_users
FROM user_dept_ratio udr
JOIN departments d ON udr.department_id = d.department_id
CROSS JOIN total_users tu
WHERE dept_ratio >= 0.35
GROUP BY d.department, tu.total_users
ORDER BY percent_of_total_users DESC;

---- Department average add to cart order
SELECT 
    d.department AS department_name,
    ROUND(AVG(opp.add_to_cart_order*1.0), 2) AS avg_add_to_cart_order
FROM order_products__prior opp
JOIN products p ON opp.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY avg_add_to_cart_order;
-- Total items per department
SELECT 
    d.department AS department_name,
    COUNT(*) AS total_items,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_products__prior), 2) AS percent_of_cart_items
FROM order_products__prior opp
JOIN products p ON opp.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY total_items DESC;
--- Departments ordered together
WITH order_departments AS (
    SELECT DISTINCT o.order_id, p.department_id
    FROM order_products__prior opp
    JOIN orders o ON opp.order_id = o.order_id
    JOIN products p ON opp.product_id = p.product_id
)
SELECT 
    d1.department AS department_1,
    d2.department AS department_2,
    COUNT(*) AS orders_together
FROM order_departments od1
JOIN order_departments od2 
    ON od1.order_id = od2.order_id AND od1.department_id < od2.department_id
JOIN departments d1 ON od1.department_id = d1.department_id
JOIN departments d2 ON od2.department_id = d2.department_id
GROUP BY d1.department, d2.department
ORDER BY orders_together DESC;






































