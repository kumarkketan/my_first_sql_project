use first_project;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name,
    CONCAT(ROUND((population * 0.25) / 1000000, 2),
            ' M') AS Coffee_consuming_population
FROM
    city
ORDER BY 2 DESC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    city_name, SUM(total) AS 'Total_Revenue'
FROM
    city c
        JOIN
    customers c1 ON c.city_id = c1.city_id
        JOIN
    sales s ON s.customer_id = c1.customer_id
WHERE
    YEAR(sale_date) = 2023
        AND QUARTER(sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    product_name, COUNT(*) AS Total_qty
FROM
    products p
        LEFT JOIN
    sales s ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?


SELECT 
    city_name,
    COUNT(DISTINCT c1.customer_id) AS Total_customer,
    SUM(total) / COUNT(DISTINCT c1.customer_id) AS Avg_sales_amount
FROM
    city c
        JOIN
    customers c1 ON c.city_id = c1.city_id
        JOIN
    sales s ON c1.customer_id = s.customer_id
GROUP BY 1
ORDER BY 3 DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

Select city_name, population, ROUND(population * 0.25) AS Coffee_consuming_population, 
COUNT(DISTINCT c1.customer_id) AS Total_customer from city c join customers c1 on c1.city_id = c.city_id
group by 1,2;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

With cte1 as 
			(Select city_id,city_name from city),
	cte2 as 
			(Select city_id,customer_id from customers),
	cte3 as 
			(Select product_id, product_name from products),
	cte4 as 
			(Select product_id, customer_id, total from sales),
	cte5 as 
			(Select city_name,product_name,sum(total) as Total_sale, 
			dense_rank() over(partition by city_name order by sum(total) desc) as rnk
			from cte1 join cte2 on cte1.city_id = cte2.city_id
			join cte4 on cte2.customer_id = cte4.customer_id
			join cte3 on cte4.product_id = cte3.product_id
			group by 1,2)

SELECT 
    city_name, product_name, Total_sale
FROM
    cte5
WHERE
    rnk < 4;
    
-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased drinking coffee products?

SELECT 
    city_name, COUNT(DISTINCT c1.customer_id) AS Total_customers
FROM
    city c
        JOIN
    customers c1 ON c.city_id = c1.city_id
        JOIN
    sales s ON s.customer_id = c1.customer_id
GROUP BY 1
ORDER BY 2 DESC;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

with avg_sale as (SELECT 
    city_name,
    COUNT(DISTINCT c1.customer_id) as Total_cus,
    Round(SUM(total) / COUNT(DISTINCT c1.customer_id),2) AS Avg_sales_amount
FROM
    city c
        JOIN
    customers c1 ON c.city_id = c1.city_id
        JOIN
    sales s ON c1.customer_id = s.customer_id
GROUP BY 1),
avg_rent as (SELECT 
    c.city_name,
    Round(estimated_rent / Total_cus,2) AS Avg_rent_amount
FROM
    city c
        JOIN
    avg_sale ON c.city_name = avg_sale.city_name)

SELECT 
    avg_rent.city_name, Avg_sales_amount, Avg_rent_amount
FROM
    avg_sale
        JOIN
    avg_rent ON avg_rent.city_name = avg_sale.city_name;
    

    
    
-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with cte as (Select city_name, year(sale_date) as Years, month(sale_date) as months, sum(total) as Total_sale
from city c join customers c1 ON c.city_id = c1.city_id 
JOIN sales s ON c1.customer_id = s.customer_id
group by 1,2,3),
cte1 as (Select * , concat(round(((Total_sale - lag(Total_sale) over(partition by city_name order by Years,months)) /
lag(Total_sale) over(partition by city_name order by Years,months))*100,2)," %")
as Monthly_Growth from cte)

SELECT * from cte1 where Monthly_Growth is not null;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers

with cte as (Select city_name,estimated_rent,sum(total) as Total_sale ,COUNT(DISTINCT c1.customer_id) as Total_cus,
rank() over(order by sum(total) desc) as rnk
from city c join customers c1 ON c.city_id = c1.city_id 
JOIN sales s ON c1.customer_id = s.customer_id
group by 1,2)

SELECT 
    city_name, estimated_rent, Total_sale, Total_cus
FROM
    cte
WHERE
    rnk < 4;
    
-- Q.11 
-- Find the percentage contribution of each product to the total revenue.

SELECT 
    product_name,
    CONCAT(ROUND((SUM(total) / (SELECT 
                            SUM(total)
                        FROM
                            sales)) * 100,
                    2),
            ' %') AS contribution
FROM
    products p
        JOIN
    sales s ON s.product_id = p.product_id
GROUP BY 1;

-- Q.12
-- Identify customers who have purchased products from more than 3 different cities.

SELECT 
    c.customer_id, c.customer_name
FROM
    customers c
        JOIN
    sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id , c.customer_name
HAVING COUNT(DISTINCT c.city_id) > 3;

-- it will give empty dataset as there is no customer who has purchased from more than 3 different cities.

-- Q.13
-- Retrieve a list of customers who have never made a purchase.

SELECT 
    customer_name
FROM
    customers c
        LEFT JOIN
    sales s ON c.customer_id = s.customer_id
WHERE
    sale_id IS NULL;
    
-- giving empty column as their is no customer who has never made a order...

-- Q.14
-- Find the difference in total sales between the best and worst-performing products.

with cte as (Select product_name, sum(total) as Total
from products p join sales s on p.product_id = s.product_id
group by 1
order by 2 desc),
cte1 as (Select first_value(Total) over() - 
last_value(Total) over(rows between unbounded preceding and unbounded following) as difference from cte)

Select difference from (Select *,row_number() over() as number1 from cte1)t where number1 =1;