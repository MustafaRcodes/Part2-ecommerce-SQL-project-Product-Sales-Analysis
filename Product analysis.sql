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

SELECT DISTINCT
    -- website_session_id,
    website_pageviews.pageview_url,
    COUNT(DISTINCT website_pageviews.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_pageviews.website_session_id) AS viewed_product_to_order_rate
FROM  website_pageviews
   LEFT JOIN orders
     ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at BETWEEN '2013-02-01' AND '2013-03-01'
    AND website_pageviews.pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
GROUP BY  1;

-- PRODUCT PATHING ANALYSIS --

-- Now we have new product, lets pull clickthrough rates from /product since the new product launch on 
-- Jan 6th 2023, by product and compare to the 3 months leading up to launch as a baseline.and

-- Step 1: finding the products pageview we care about
CREATE TEMPORARY TABLE products_pageviews
SELECT 
    website_session_id,
    website_pageview_id,
    created_at,
    CASE 
      WHEN created_at < '2013-01-06' THEN 'A.Pre_product_2'
      WHEN created_at >= '2013-01-06' THEN 'B.Post_product_2'
      ELSE 'check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at < '2013-04-06' 
     AND created_at > '2012-10-06'
     AND pageview_url = '/products';
     
-- Step 2: find the next pageview id that occurs AFTER the product pageview
CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT 
   products_pageviews.time_period,
   products_pageviews.website_session_id,
   products_pageviews.website_pageview_id,
   MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews
   LEFT JOIN website_pageviews
     ON website_pageviews.website_session_id = products_pageviews.website_session_id
     AND website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
GROUP BY 1,2,3;

-- Step 3: find the pageview_url associated with any applicable next pageview id
CREATE TEMPORARY TABLE sessions_w_next_pageview_url 
SELECT 
    sessions_w_next_pageview_id.time_period,
    sessions_w_next_pageview_id.website_session_id,
    sessions_w_next_pageview_id.min_next_pageview_id,
    website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
   LEFT JOIN website_pageviews
        ON website_pageviews.website_pageview_id = sessions_w_next_pageview_id.min_next_pageview_id;
        
-- Step 4: summarize the data and anlayze the pre and post period
SELECT
    time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_mtfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM 
    sessions_w_next_pageview_url
GROUP BY time_period;
   
-- Looks like the percent of /products pageviews that clicked to Mr.fuzzy has gone down since the launch of the love Bear,
-- but the overall clickthrough rate has gone up, so it seems to be generating additional product interest overall.
-- We should look at the conversion funnel for each product individually.alter

-- BUILDING PRODUCT LEVEL CONVERSION FUNNELS-- 