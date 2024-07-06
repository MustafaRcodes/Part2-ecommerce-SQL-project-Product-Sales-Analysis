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
-- We launched our second product back in Jan 6th. We need to pull together soem trend analysis.
-- We need to pull monthly order volume, overall conversion rates, revenue per session and breakdown of
-- sales by product, all for the time period since April 1, 2022

SELECT 
    YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_order,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_order
FROM website_sessions
    LEFT JOIN orders
        ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-04-05'
    AND website_sessions.created_at > '2012-04-01'
GROUP BY 1,2;

-- Conversion rate and revnue per session are improving over time  which is great
-- I believe growth since Jan is due to the new product launch or may be due to the overall improvement in business and product one. 
-- We can see growth in product two sales from Jan which is great that means product two has potential to grow further

-- PRODUCT LEVEL WEBSITE ANALYSIS -- 
/*
Product focused website analysis to learn how customers interact with each of our product and how 
well each product converts customer. Undertanding which of our products generate the most interest on 
multi-product showcase pages. Analyzing the impact on website conversion rates when we add a new product.
Building product-specific conversion funnels to understand whether certain products convert better than others.
*/

