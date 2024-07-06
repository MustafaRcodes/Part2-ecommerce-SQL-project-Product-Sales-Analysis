-- PRODUCT ANALYSIS -- 
/*
PRODUCT SALES ANALYSIS 
ANALYZING PRODUCT SALES HELPS TO UNDERSTAND HOW EACH PRODUCT CONTRIBUTES TO OUR BUSINESS AMD HOW PRODUCT 
LAUNCHES IMPACT THE OVERALL PORTFOLIO
*/

-- ANALYZING PRODUCT SALES AND PRODUCT LAUNCHES 

SELECT
   primary_product_id,
   COUNT(order_id) AS orders,
   SUM(price_usd) AS revenue,
   SUM(price_usd - COGS_USD) AS margin,
   AVG(price_usd) AS average_order_value 
FROM orders
WHERE order_id BETWEEN 10000 AND 11000
GROUP BY 1
ORDER BY 2 DESC;

-- PRODUCT LEVEL SALES ANALYSIS -- 

-- Pulling monthly trend to data for number of sales, total revenue, and total margin generated for business.alter

SELECT
    YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT order_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM 
    orders
WHERE created_at < '2013-01-04'
GROUP BY 
    YEAR(created_at),
    MONTH(created_at);

-- Insights are helpful to undertand how revenue and margin evolve as we roll out the new product
-- Nice to see growth pattern 

-- ANALYZING A PRODUCT LAUNCHES --
