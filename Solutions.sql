-- Monday Coffee -- Data Analysis 

SELECT * FROM sales
SELECT * FROM products
SELECT * FROM customers
SELECT * FROM city

-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?


SELECT
	city_name,
	ROUND((25.0/100)*cast(population AS int),2) AS cofee_consumers
FROM city 
ORDER BY 2 DESC

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT 
	SUM(total) AS total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4

----------------------------------------

SELECT 
	ci.city_name,
	SUM(total) AS total_revenue
FROM sales s 
JOIN customers c USING(customer_id)
JOIN city ci ON ci.city_id=c.city_id
WHERE 
	EXTRACT(YEAR FROM sale_date)=2023 
	AND 
	EXTRACT(quarter FROM sale_date)=4
GROUP BY 1
ORDER BY 2 DESC


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?


SELECT 
	p.product_name,
	COUNT(s.product_id) AS product_count
FROM sales s
LEFT JOIN products p ON s.product_id=p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT c.customer_id) AS total_customers,
	round(SUM(s.total):: numeric /COUNT(DISTINCT c.customer_id):: numeric ,2) AS avg_sales_person
FROM sales s
JOIN customers c ON s.customer_id=c.customer_id
JOIN city ci ON ci.city_id=c.city_id
GROUP BY 1
ORDER BY 2 DESC

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH sales_table AS 
(SELECT 
	city_name,
	round((25.0/100)*population,2) AS coffee_consumers
FROM city ),
customers_table AS 
(SELECT 
	ci.city_name ,
	COUNT(DISTINCT c.customer_id) AS unique_customers
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id=c.city_id
GROUP BY 1)

SELECT 
	city_name,
	coffee_consumers,
	unique_customers
FROM sales_table JOIN customers_table USING(city_name)
	


-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?


SELECT 
	* 
FROM
(SELECT 
	ci.city_name,
	p.product_name,
	COUNT(s.product_id) AS product_count,
	RANK() OVER (PARTITION BY city_name ORDER BY COUNT(s.product_id) DESC) AS ranks
FROM sales s 
JOIN products p USING(product_id)
JOIN customers c ON c.customer_id=s.customer_id
JOIN city ci ON ci.city_id=c.city_id
GROUP BY 2,1
--order by 1 desc
)
WHERE ranks <=3

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id)
FROM city ci
JOIN customers c  USING(city_id)
JOIN sales s USING(customer_id)
WHERE s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1



-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer


SELECT 
	city_name,
	ROUND(SUM(total)::NUMERIC/COUNT( DISTINCT customer_id)::NUMERIC,2) AS average_sale_per_customer ,
	ROUND(AVG(estimated_rent)::NUMERIC/COUNT(DISTINCT customer_id)::NUMERIC,2) AS average_rent_per_customer
FROM sales s 
JOIN customers c USING(customer_id)
JOIN city ci ON ci.city_id=c.city_id
GROUP BY 1
ORDER BY 3

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

SELECT 
	*,
	ROUND((total_revenue - last_month)::NUMERIC/last_month::NUMERIC ,2)AS growth_ratio
FROM 
(SELECT 
	city_name,
	EXTRACT(Year FROM sale_date) AS Year,
	EXTRACT(Month FROM sale_date) AS Month,
	SUM(total) AS total_revenue,
	LAG(SUM(total)) OVER(PARTITION BY city_name ORDER BY EXTRACT(Year FROM sale_date),EXTRACT(Month FROM sale_date))AS last_month
FROM sales s 
JOIN customers c USING(customer_id) 
JOIN city ci ON ci.city_id=c.city_id
GROUP BY 1,2,3
ORDER BY 1,2,3) AS T1
WHERE last_month IS NOT NULL


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS 
(SELECT 
	city_name,
	SUM(total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_customers,
	ROUND(SUM(total)::NUMERIC/COUNT( DISTINCT customer_id)::NUMERIC,2) AS average_sale_per_customer ,
	ROUND(AVG(estimated_rent)::NUMERIC/COUNT(DISTINCT customer_id)::NUMERIC,2) AS average_rent_per_customer
FROM sales s 
JOIN customers c USING(customer_id)
JOIN city ci ON ci.city_id=c.city_id
GROUP BY 1),
est_customers_rend AS 
(
SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) AS estimated_coffee_consumer_in_millions
FROM city
)
SELECT 
	ct.city_name,
	total_revenue,
	estimated_rent,
	total_customers,
	estimated_coffee_consumer_in_millions,
	average_sale_per_customer,
	average_rent_per_customer
FROM city_table AS ct
JOIN est_customers_rend AS est
ON ct.city_name = est.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.