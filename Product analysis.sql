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

-- I would like to look at our two products since january 6th and analyze the conversion funnels 
-- from each product page to conversion.
-- Need to produce a comparison between the two conbersion funnels, for all website traffic.

-- Step 1: select all pageviews for relevant sessions
-- step 2: figure out which pageview urls to look for 
-- step 3: pull all pageviews and identify the funnel steps
-- step 4: create the session-level conversion funnelview 
-- step 5: aggregate the data to assess funnel performance 

CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT 
    website_session_id,
    website_pageview_id,
    pageview_url AS product_page_seen
FROM
    website_pageviews
WHERE created_at < '2013-04-10'
   AND created_at > '2013-01-06'
   AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');
   
  -- finding the right pageview_urls to build the funnels
  SELECT DISTINCT
     website_pageviews.pageview_url
  FROM sessions_seeing_product_pages
    LEFT JOIN website_pageviews
        ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;
        
-- We will look at the inner query first to look over the pageview-level results
-- then, turn it into a subquery and make it the summary with flag

SELECT 
   sessions_seeing_product_pages.website_session_id,
   sessions_seeing_product_pages.product_page_seen,
   CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
   CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
   CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
   CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanyou_page
FROM sessions_seeing_product_pages
   LEFT JOIN website_pageviews
     ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
     AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY 
     sessions_seeing_product_pages.website_session_id,
     website_pageviews.created_at;
 
CREATE TEMPORARY TABLE session_product_level_made_it_flags 
SELECT 
    website_session_id,
    CASE 
       WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
       WHEN product_page_seen = '/the-forever-love-bear' THEN 'love-bear'
       ELSE 'check logic'
       END AS product_seen,
	MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
    FROM(
    SELECT
        sessions_seeing_product_pages.website_session_id,
        sessions_seeing_product_pages.product_page_seen,
        CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
        CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
        CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
     FROM sessions_seeing_product_pages
        LEFT JOIN website_pageviews
        ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
	  ORDER BY
        sessions_seeing_product_pages.website_session_id,
        website_pageviews.created_at
	) AS pageview_level
    GROUP BY 
      website_session_id,
      CASE 
       WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
       WHEN product_page_seen = '/the-forever-love-bear' THEN 'love-bear'
       ELSE 'check logic'
       END;
       
-- Final output part 1
SELECT 
    product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;

-- Final output part 2 -- click rates
SELECT 
    product_seen,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_page_click_rate,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_clikc_rate,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rate,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rate
FROM session_product_level_made_it_flags
GROUP BY product_seen;

-- This analysis shows that the love bear has a better click rate to the /cart page and comparable rates 
-- throughout the rest of the funnel.
-- seems like the second product was a great addition for our business.

-- CROSS SELLING PRODUCT AND PRODUCT PORTFOLIO ANALYSIS --
/* Cross selling analysis is about undertanding which product users are most likely to purchase together
and offering smart product recommendation.
Need to understand which products are often purchase together 
Testing and optimizing the way we cross-sell products on our website
Understanding the conversion rate impact and the overall revenue impact of trying to cross-selladditional
product.
*/

SELECT * FROM order_items
WHERE order_id BETWEEN 10000 AND 11000;

SELECT
   orders.order_id,
   orders.primary_product_id,
   order_items.product_id AS cross_sell_product
FROM orders
   LEFT JOIN order_items
     ON order_items.order_id = orders.order_id
     AND order_items.is_primary_item = 0 -- cross sell only, which is 0
WHERE orders.order_id BETWEEN 10000 AND 11000;

SELECT
   orders.primary_product_id,
   order_items.product_id AS cross_sell_product,
   COUNT(DISTINCT orders.order_id)  AS orders
FROM orders
   LEFT JOIN order_items
     ON order_items.order_id = orders.order_id
     AND order_items.is_primary_item = 0 -- cross sell only, which is 0
WHERE orders.order_id BETWEEN 10000 AND 11000 
GROUP BY 1,2;

SELECT
   orders.primary_product_id,
   COUNT(DISTINCT orders.order_id)  AS orders,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS X_sell_prod1,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS X_sell_prod2,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS X_sell_prod3
FROM orders
   LEFT JOIN order_items
     ON order_items.order_id = orders.order_id
     AND order_items.is_primary_item = 0 -- cross sell only, which is 0
WHERE orders.order_id BETWEEN 10000 AND 11000
GROUP BY 1;

-- Another way of writing the query to get result same as above --

SELECT
   orders.primary_product_id,
   COUNT(DISTINCT orders.order_id) AS orders,  -- Total distinct orders
   COUNT(DISTINCT CASE WHEN order_items.product_id = 1 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END) AS X_sell_prod1,  -- Orders containing product_id 1 as cross-sell
   COUNT(DISTINCT CASE WHEN order_items.product_id = 2 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END) AS X_sell_prod2,  -- Orders containing product_id 2 as cross-sell
   COUNT(DISTINCT CASE WHEN order_items.product_id = 3 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END) AS X_sell_prod3   -- Orders containing product_id 3 as cross-sell
FROM orders
   LEFT JOIN order_items
     ON order_items.order_id = orders.order_id
WHERE orders.order_id BETWEEN 10000 AND 11000
GROUP BY orders.primary_product_id;


SELECT
   orders.primary_product_id,
   COUNT(DISTINCT orders.order_id) AS orders,  -- Total distinct orders
   COUNT(DISTINCT CASE WHEN order_items.product_id = 1 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END) AS X_sell_prod1,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 2 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END) AS X_sell_prod2,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 3 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END) AS X_sell_prod3,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 1 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) AS X_sell_prod1_rate,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 2 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) AS X_sell_prod2_rate,
   COUNT(DISTINCT CASE WHEN order_items.product_id = 3 AND order_items.is_primary_item = 0 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) AS X_sell_prod3_rate
FROM orders
   LEFT JOIN order_items
     ON order_items.order_id = orders.order_id
WHERE orders.order_id BETWEEN 10000 AND 11000
GROUP BY orders.primary_product_id;



-- On september 25th we started giving customers the option to add a 2nd product while on the /cart page.
-- We need to compare the month before vs the month after the change. we would like to see CTR from the
-- /cart page, avg product per order, AOV, and overall revenue per/cart page view. 

-- CROSS SALES ANALYSIS -- 
-- Step 1: Identify the relevant /cart page view and their sessions
-- Step 2: See which of those /cart sessions clicked through to the shipping page.
-- Step 3: Find the orders associated with the /cart sessions. Analyze products purchased, AOV
-- Step 4: Aggregate and analyze a summary of our finding.

CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT 
   CASE 
   WHEN created_at < '2013-09-25' THEN  'A. Pre_Cross_Sell'
   WHEN created_at >= '2013-01-06' THEN 'B. Post_Cross_Sell'
   ELSE 'check logic'
   END AS time_period,
     website_session_id AS  cart_session_id,
     website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
    AND pageview_url = '/cart';
    
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT 
   sessions_seeing_cart.time_period,
   sessions_seeing_cart.cart_session_id,
   MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart
   LEFT JOIN website_pageviews
     ON website_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
     AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
GROUP BY 
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id
HAVING 
     MIN(website_pageviews.website_pageview_id) IS NOT NULL;
     
CREATE TEMPORARY TABLE pre_post_sessions_orders 
SELECT 
    time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
    
FROM  sessions_seeing_cart
     INNER JOIN orders
        ON sessions_seeing_cart.cart_session_id = orders.website_session_id;
        
-- first, we'll look at this select statement 
-- then we'll turn it into a subquery

SELECT 
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS place_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
	LEFT JOIN cart_sessions_seeing_another_page
       ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
	LEFT JOIN pre_post_sessions_orders
       ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id
;
    
 SELECT 
    time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr,
    -- SUM(placed_order) AS orders_placed,
    -- SUM(items_purchased) AS products_purchased,
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    -- SUM(price_usd) AS revenue,
    SUM(price_usd)/SUM(placed_order) AS aov,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM(
SELECT 
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
	LEFT JOIN cart_sessions_seeing_another_page
       ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
	LEFT JOIN pre_post_sessions_orders
       ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY 
     cart_session_id
) AS full_data
GROUP BY time_period;

-- It looks like the CTR from the /cart page didn't go down and that our product per order, AOV and 
-- revenue per/cart session are all up slightly since the cross-sell feature was added.


-- PRODUCT PORTFOLIO EXPANSION --
-- will run a pre-post analysis comparing the month before vs the month after, in terms of session-to-order
-- conversion rate, AOV, product per order and revenue per session.

SELECT 
   CASE 
      WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
      WHEN website_sessions.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
      ELSE 'check logic'
END AS time_period,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
SUM(orders.price_usd) AS total_revenue,
SUM(orders.items_purchased) AS total_product_sold,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS average_order_value,
SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
   LEFT JOIN orders
     ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

-- It looks like all of our critical metrics have improved since we launched the third product.
-- we may consider adding a fourth product.


-- PRODUCT REFUND ANALYSIS -- 
/* Analyzing product refund rates is about controlling for quanlity and understanding where 
we might have problems to address.
Keeping a eye on refund rates is a great way to analyze the relative quality of product, track customer
satisfaction and to undertand overall business health.
- Monitoring products from different suppliers.
- Undertanding refund rates for products at different price point.
- Taking product refund rates and the associated costs into account when assessing the overall perfromance
of our business.
*/
SELECT 
    order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd AS price_paid_usd,
    order_items.created_at,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at
FROM order_items
    LEFT JOIN order_item_refunds
        ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.order_id IN (3489,32049,27061);

-- Supplier has some quality issues which weren't corrected until september 2013.
-- Major problem is bear's arms were falling off in Aug/Sep 2014. as a result we replaced it with a new 
-- supplier on September 16, 2014
-- We need to pull monthly product refund rates by product, and confirm  our quanlity issues are now fixed.alter

SELECT 
   YEAR(order_items.created_at) AS yr,
   MONTH(order_items.created_at) AS mo,
   COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
   COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END)
       /COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END ) AS p1_refund_rt,
   COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
   COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refunds.order_item_id ELSE NULL END)
       /COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END ) AS p2_refund_rt,
   COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
   COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END)
       /COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END ) AS p3_refund_rt,
   COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
   COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END)
       /COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END ) AS p4_refund_rt
FROM order_items
	LEFT JOIN order_item_refunds
       ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;

-- Looks like the refund rates did go down after the initial improvements in september 2013,
-- but refund rate were terrible in August and September, as expected 13-14 %.
-- Seems like the new supplier is doing much better and the other products looks ok to.