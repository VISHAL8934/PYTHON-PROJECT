CREATE DATABASE day22;



SELECT * FROM day22.city;

SELECT * FROM day22.`customers (1)`;

SELECT * FROM day22.`products (1)`;

SELECT * FROM day22.sales;

--                                   *REPORTS AND DATA ANALYSIS*

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
 city_name,
(population * 0.25)/1000000 as coffee_consumers_in_millions,
 city_rank
FROM day22.city
order by 2 desc

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM day22.sales s
JOIN day22.`customers (1)` AS c
    ON s.customer_id = c.customer_id
JOIN day22.city AS ci
    ON ci.city_id = c.city_id
WHERE 
    EXTRACT(YEAR FROM s.sale_date) = 2023
    AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM day22.`products (1)` as p
LEFT JOIN day22.sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city	

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    SUM(s.total) / COUNT(DISTINCT s.customer_id) AS avg_sale_cg_px
FROM day22.sales s
JOIN day22.`customers (1)` AS c
    ON s.customer_id = c.customer_id
JOIN day22.city AS ci
    ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS 
(
    SELECT 
        city_name,
        ROUND((population * 0.25)/1000000, 2) AS coffee_consumers
    FROM day22.city
),

customers_table AS
(
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM day22.sales s
    JOIN day22.`customers (1)` c
        ON c.customer_id = s.customer_id
    JOIN day22.city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)

SELECT 
    ct.city_name,
    ct.coffee_consumers,
    cu.unique_cx,
    ROUND(
        (cu.unique_cx / (ct.coffee_consumers * 1000000))*100,
        2
    ) AS penetration_percent

FROM city_table ct
JOIN customers_table cu
    ON ct.city_name = cu.city_name;
    
-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rnk
    FROM day22.sales s
    JOIN day22.`products (1)` p
        ON s.product_id = p.product_id
    JOIN day22.`customers (1)` c
        ON c.customer_id = s.customer_id
    JOIN day22.city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) AS t1
WHERE rnk <= 3
ORDER BY city_name, rnk;   

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM day22.`products (1)`;

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_cx
FROM day22.city AS ci
LEFT JOIN day22.`customers (1)` AS c
    ON c.city_id = ci.city_id
JOIN day22.sales AS s
    ON s.customer_id = c.customer_id
WHERE 
    s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY ci.city_name;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM day22.sales s
    JOIN day22.`customers (1)` c
        ON s.customer_id = c.customer_id
    JOIN day22.city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_rent AS
(
    SELECT 
        city_name, 
        estimated_rent
    FROM day22.city
)

SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct
    ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS
(
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM day22.sales s
    JOIN day22.`customers (1)` c
        ON c.customer_id = s.customer_id
    JOIN day22.city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, YEAR(s.sale_date), MONTH(s.sale_date)
),

growth_ratio AS
(
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale) OVER(
            PARTITION BY city_name 
            ORDER BY year, month
        ) AS last_month_sale
    FROM monthly_sales
)

SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        ((cr_month_sale - last_month_sale) / last_month_sale) * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM day22.sales s
    JOIN day22.`customers (1)` c
        ON s.customer_id = c.customer_id
    JOIN day22.city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_rent AS
(
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3)
            AS estimated_coffee_consumer_in_millions
    FROM day22.city
)

SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct
    ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;

















































