---======================= User Retention & Business Decision Impact Analysis ====================================================================================

/* 1.Quantify customer retention by segmenting delivered-order customers into one-time shoppers and repeat loyalists. 
Determine the population distribution and relative segment ratios to establish a baseline for brand loyalty and its potential impact 
on customer acquisition costs. */

WITH customer_purchase_counts AS( SELECT COUNT(o.order_id) AS order_count, c.customer_unique_id
FROM orders AS o INNER JOIN customers AS c on o.customer_id = c.customer_id
WHERE order_status = 'delivered'
GROUP BY c.customer_unique_id),Segment AS(
SELECT 
CASE WHEN order_count = 1 THEN 'One-time shoppers'
WHEN order_count > 1 THEN 'Repeat loyalist'
END AS Shoppers,COUNT(*) AS Customer_count
FROM customer_purchase_counts
GROUP BY 1)
SELECT Shoppers,Customer_count,
ROUND(Customer_count * 100.0 / SUM(Customer_count) OVER(),2) AS "Population pct",
ROUND(Customer_count * 1.0 / SUM(Customer_count) OVER(),2) AS "Segment Ratio"
FROM Segment;

/* Insight: 97% customers are one-time shoppers, showing extremely low repeat purchase behaviour.
Only 3% customers return, indicating weak customer loyalty and poor retention strength.
Recommendation : Focus on improving first purchase experience (delivery, product satisfaction, support) to increase repeat rate.
Introduce retention strategies like discounts, reminders, or loyalty rewards to convert one-time buyers into repeat customers.*/

/* 2 Identify each customer’s acquisition cohort by determining the month of their first delivered purchase.
 This establishes the foundation for cohort-based retention analysis. */

WITH cohorts AS (
    SELECT C.customer_unique_id,DATE_TRUNC('month', MIN(O.order_purchase_timestamp))::date AS cohort_month
    FROM orders AS O INNER JOIN customers AS C ON O.customer_id = C.customer_id
    WHERE order_status = 'delivered'
    GROUP BY C.customer_unique_id)
SELECT customer_unique_id,cohort_month
FROM cohorts
ORDER BY cohort_month;

/*Insight: 93,358 customers have been assigned a cohort based on their first delivered purchase month.
Recommendation: Use cohort field as the base for retention and lifecycle analysis.*/

/* 3 Define and measure active customers by calculating the number of unique customers who made a purchase within recent time windows 
 (e.g., last 30 days vs 60 days). This helps assess current engagement and platform activity levels. */

WITH Lastest_date AS (
SELECT MAX(order_purchase_timestamp) AS Max_date
FROM orders), 
order_status AS(
SELECT c.customer_unique_id,o.order_purchase_timestamp,o.order_status
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered')

SELECT COUNT(DISTINCT CASE WHEN order_purchase_timestamp >=(SELECT Max_date FROM Lastest_date) - INTERVAL '30 days' 
THEN customer_unique_id END) AS Active_30_days,
COUNT(DISTINCT CASE WHEN order_purchase_timestamp >=(SELECT Max_date FROM Lastest_date) - INTERVAL '60 days' THEN customer_unique_id END)
AS Active_60_days
FROM order_status;

/* Insight: Active customers in the last 30 days are 0, meaning there is no recent customer activity.
In the last 60 days, some customers are active, but they still stop returning after a short time.
Recommendation: Immediately run reactivation campaigns (emails, WhatsApp offers, discounts) to bring back inactive customers.
Improve post-purchase engagement so customers return within 30 days instead of going inactive.*/

/* 4 Analyze monthly active customer trends across different years to determine 
whether observed fluctuations are driven by seasonal patterns or indicate abnormal changes in customer behaviour.*/

SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp ) AS Month,
       EXTRACT(YEAR FROM o.order_purchase_timestamp) AS Year,
	   COUNT(DISTINCT C.customer_unique_id) AS Active_users
FROM orders AS o INNER JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY Year, Month
ORDER BY Year,Month;  -- Black Friday" Peak (Why 2017 Month 11 is high)


/* Insight: Customer activity increases strongly over time, showing steady business growth from 2017 to 2018.
There is a clear peak in November 2017, which is likely due to seasonal shopping events like Black Friday sales.

Recommendation : Plan major marketing campaigns around high-performing months like November to maximize sales impact.
Investigate low months (early 2016 and mid-2017) and improve marketing efforts during slow periods. */

/* 5 Evaluate the relationship between delivery performance (on-time vs late) and customer retention 
by analyzing repeat purchase behaviour across different delivery experience segments. */

WITH first_order AS (
          SELECT DISTINCT ON (c.customer_unique_id) c.customer_unique_id,o.order_id,o.order_purchase_timestamp,
          CASE WHEN o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE THEN 'Late' ELSE 'On Time' END AS 
          delivery_preformance
FROM orders AS o INNER JOIN customers AS c on o.customer_id = c.customer_id
WHERE order_status = 'delivered' AND  o.order_delivered_customer_date IS NOT NULL 
      AND o.order_estimated_delivery_date IS NOT NULL
ORDER BY customer_unique_id,o.order_purchase_timestamp ASC),

Total_Orders AS( SELECT c.customer_unique_id,COUNT(o.order_id) AS Total_Orders
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)

SELECT f.delivery_preformance,COUNT(*) AS total_customers,
	   SUM(CASE WHEN t.Total_Orders > 1 THEN 1 ELSE 0 END) AS Retained_customers,
       ROUND(SUM(CASE WHEN t.Total_Orders > 1 THEN 1 ELSE 0 END ) * 100.0 / COUNT(*),2)AS repeat_purchase_rate
FROM first_order AS f INNER JOIN total_orders AS t ON f.customer_unique_id = t.customer_unique_id
GROUP BY f.delivery_preformance;

/*Insight : On-time deliveries have a higher repeat purchase rate (3.04%) compared to late deliveries (2.52%).
This shows that delivery performance has a direct impact on customer retention.
Recommendation : Improve logistics to reduce late deliveries and ensure faster, reliable shipping.
Focus especially on first-order delivery experience to increase customer repeat purchases.*/

-- 6 Weekend vs Weekday order distribution analysis

SELECT c.day_type, COUNT(*) AS total_orders
FROM orders AS o INNER JOIN calender_table AS c ON o.order_purchase_timestamp::date = c.datekey
WHERE o.order_status = 'delivered'
GROUP BY c.day_type;

/*Insight: Weekday orders are much higher (74288) compared to weekend orders (22190).

Recommendations: Focus operations, staffing, and campaigns more on weekdays, since most orders are placed during this period.*/

-- 7 Calculate revenue loss if 5% of top 20% high-value customers don’t return next quarter.

WITH customer_spend AS (
SELECT c.customer_unique_id, SUM(p.payment_value) AS revenue
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id
INNER JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id),

top_customers AS (SELECT *
FROM customer_spend
ORDER BY revenue DESC
LIMIT (SELECT CAST(COUNT(*) * 0.2 AS INT) FROM customer_spend))

SELECT ROUND(SUM(revenue) * 0.05,2) AS revenue_loss_estimate
FROM top_customers;

/*Insight: Revenue loss estimate from top 20% high-value customers is 412,733.28.
Top 20% customers contribute a significant portion of total revenue.

Recommendation: Focus on maintaining high-value customer contribution to revenue. Track high-value customer revenue contribution regularly. */

-- 8 Which product categories have the highest average time between repeat purchases?

WITH customer_orders AS (SELECT c.customer_unique_id,t.product_category_name_english AS product_category_name,
 o.order_purchase_timestamp::DATE AS order_date,LAG(o.order_purchase_timestamp::DATE) 
 OVER (PARTITION BY c.customer_unique_id, t.product_category_name_english ORDER BY o.order_purchase_timestamp) AS prev_order_date
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id INNER JOIN order_items AS i ON i.order_id = o.order_id
INNER JOIN products AS p ON p.product_id = i.product_id LEFT JOIN product_category_name_translation AS t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered')
SELECT product_category_name,ROUND(AVG(order_date - prev_order_date), 2) AS avg_days_between_purchases
FROM customer_orders
WHERE prev_order_date IS NOT NULL  
GROUP BY product_category_name
ORDER BY avg_days_between_purchases DESC; -- Low days = High retention (customers return fast)

/*Insight: fashion_bags_accessories (13.36 days) and musical_instruments (12.75 days) have the highest average time between repeat purchases.
electronics (1.95 days) and furniture_decor (1.67 days) have low average time between repeat purchases.

Recommendation: Focus on categories with high repeat purchase time to improve customer return speed.
Maintain performance in categories with low repeat purchase time as they show faster repeat buying.*/

-- 9 How much revenue does an average customer generate?

SELECT ROUND(AVG(customer_revenue),2) AS Average_revenue
FROM (SELECT c.customer_unique_id,SUM(p.payment_value) AS customer_revenue
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id INNER JOIN order_payments AS p ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY customer_unique_id) AS customer_revenue_table;

/*Insight: Average revenue per customer is 165.20.
Each customer generates around this amount on average.
Recommendation:  Use this value to track customer value over time and focus on increasing average customer spend.*/

-- 10 How is revenue distributed across our customer base by quintile?

WITH Customer_Revenue AS (SELECT C.customer_unique_id,SUM(P.payment_value) AS Revenue 
FROM orders AS O JOIN customers AS C on O.customer_id = C.customer_id JOIN order_payments AS P ON P.order_id = O.order_id
WHERE o.order_status = 'delivered'
GROUP BY customer_unique_id ),

revenue_rank AS  (SELECT Revenue,NTILE(5) OVER (ORDER BY Revenue DESC ) AS Quintile
FROM Customer_Revenue)
SELECT Quintile,ROUND(SUM(Revenue) * 100.0 / (SELECT SUM(Revenue) FROM revenue_rank),2) AS revenue_pct
FROM revenue_rank 
GROUP BY Quintile
ORDER BY Quintile;

/*Insight: The highest revenue concentration is in Quintile 1, which contributes 53.53% of total revenue and 
revenue contribution decreases steadily from Quintile 1 to Quintile 5, showing uneven distribution across customers.
Recommendation : To analyse purchase patterns, product categories, and payment behaviour of Quintile 1 customers and apply similar strategies to other segments.
Use targeted offers, discounts, and personalized marketing to increase spending from lower quintile customers.*/

/* 11 Identify high-value customers who have not made a purchase in the last 90 days,
highlighting potential churn risk among top revenue customers.*/

WITH Customer_Spent AS(SELECT C.customer_unique_id,MAX(O.order_purchase_timestamp) AS Last_purchasedate,SUM(P.payment_value) AS Total_revenue
FROM orders AS O INNER JOIN  Customers AS C ON C.customer_id = O.customer_id INNER JOIN order_payments AS P ON  P.order_id =O.order_id
WHERE o.order_status = 'delivered'
GROUP BY C.customer_unique_id), 

Highest_value AS (
SELECT customer_unique_id,Last_purchasedate,Total_revenue,NTILE(5) OVER(ORDER BY Total_revenue DESC) revenue_quintile
FROM Customer_Spent) 

SELECT customer_unique_id, Total_revenue, Last_purchasedate
FROM Highest_value WHERE revenue_quintile = 1 AND Last_purchasedate < (SELECT MAX(Last_purchasedate) FROM Customer_Spent) 
- INTERVAL '90 DAYS';

/*Insight: 14,915 high-value customers have not made recent purchases, indicating a large inactive premium customer base.
Recommendation: Target these inactive high-value customers with re-engagement campaigns like discounts, personalized offers, and reminder emails.
Monitor high-value customer activity regularly to reduce churn and improve retention.*/

--12 Evaluate how customer review ratings influence spending behaviour by comparing average order values across different rating levels.

SELECT O.review_score,AVG(P.payment_value) Avg_order_value
FROM order_reviews AS O  INNER JOIN order_payments AS P ON O.order_id = P.order_id
GROUP BY O.review_score
ORDER BY O.review_score DESC;

/* Insight:  Customers with 1-star rating show the highest average order value (186.39) compared to all other rating groups.
Higher ratings (4–5 stars) show lower average order values (147–149), while lower ratings also vary but remain lower than 1-star group.

Recommendation: The 1-star group has the highest average order value (186.39), 
so these higher-spend orders should be prioritised for issue tracking (delivery, product mismatch, service errors) at order level.
Since all rating groups (1–5) still show similar average values (145–186 range), 
introduce rating-based monitoring on high-value orders rather than treating all low ratings equally.*/

 -- 13  Find "Loyalists"—customers whose every subsequent order amount is greater than their very first order amount.

WITH order_value AS (SELECT c.customer_unique_id AS customer_id,o.order_purchase_timestamp AS order_date,SUM(p.payment_value) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS order_rank
FROM orders AS o INNER JOIN order_payments AS p ON o.order_id = p.order_id INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id,o.order_purchase_timestamp),

first_order AS (SELECT ov.customer_id,ov.total_value AS first_value
FROM order_value AS ov
WHERE ov.order_rank = 1),

filtered AS (SELECT ov.customer_id
FROM order_value AS ov INNER JOIN first_order AS f ON ov.customer_id = f.customer_id
WHERE ov.order_rank > 1 AND ov.total_value <= f.first_value),

loyal_customers AS (SELECT ov.customer_id
FROM order_value AS ov
GROUP BY ov.customer_id
HAVING COUNT(*) > 1 AND ov.customer_id NOT IN (SELECT f.customer_id FROM filtered AS f))

SELECT ov.customer_id,ov.order_rank,ov.total_value,f.first_value
FROM order_value AS ov INNER JOIN loyal_customers AS lc ON ov.customer_id = lc.customer_id
INNER JOIN first_order AS f ON ov.customer_id = f.customer_id
ORDER BY ov.customer_id,ov.order_rank;

/*Insight: These customers show rapid trust by frequently doubling their spend on second orders.
Recommendation: Offer rewards after the first purchase to encourage these customers to spend more.*/

/* 14 Determine each customer’s “birth month” based on their first delivered purchase to support cohort segmentation 
and lifecycle analysis. */

SELECT C.customer_unique_id, DATE_TRUNC('month', MIN(O.order_purchase_timestamp))::DATE AS cohort_month
FROM customers AS C INNER JOIN orders AS O ON O.customer_id = C.customer_id
WHERE o.order_status = 'delivered'
GROUP BY C.customer_unique_id;

/*Insight: 93,358 customers have been assigned a cohort based on their first delivered purchase month.
Recommendation: Track customer cohort-wise retention to compare how different acquisition months perform in repeat purchases.
Use this cohort structure to identify which months bring more loyal customers and which months need improvement.*/

/* Q15: Build a cohort table showing how many users from Jan 2017 returned in Feb, March, etc. 
(Calculated as Month 0, Month 1, etc.).*/


WITH cohort_value  AS (SELECT C.customer_unique_id, DATE_TRUNC('month', MIN(O.order_purchase_timestamp))::DATE AS cohort_month
FROM customers AS C INNER JOIN orders AS O ON O.customer_id = C.customer_id
WHERE o.order_status = 'delivered'
GROUP BY C.customer_unique_id), 

Active_customers AS (SELECT C.customer_unique_id,CV.cohort_month,DATE_TRUNC('month',O.order_purchase_timestamp)::DATE AS Active_month
FROM cohort_value AS CV LEFT JOIN customers  AS C ON CV.customer_unique_id = C.customer_unique_id
LEFT JOIN orders AS O ON  O.customer_id = C.customer_id AND o.order_status = 'delivered')

SELECT cohort_month,Active_month, EXTRACT(Month FROM AGE(Active_month,cohort_month)) AS Month_diff,
COUNT(DISTINCT  customer_unique_id) AS NO_OF_ID
FROM Active_customers
WHERE Active_month IS NOT NULL
GROUP BY cohort_month,Active_month
ORDER BY cohort_month,Month_diff;

/*Insight: Most customers stop interacting with the brand immediately after their first purchase.

Recommendation: Review the post-purchase experience to find better ways to keep users interested.*/
                    
/* Q16: Compare the average total spend (LTV) of users who gave and compare LTV of customers based on first order review score (1-star vs 5-star) */

WITH first_order_rating AS (SELECT c.customer_unique_id,r.review_score,ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id 
      ORDER BY o.order_purchase_timestamp) AS order_rank
FROM orders AS o INNER JOIN order_reviews AS r ON o.order_id = r.order_id INNER JOIN customers AS c ON c.customer_id = o.customer_id WHERE o.order_status = 'delivered'),

customer_ltv AS (SELECT  c.customer_unique_id,SUM(p.payment_value) AS total_spend
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id INNER JOIN order_payments AS p  ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)

SELECT f.review_score,COUNT(*) AS total_customers, ROUND(AVG(l.total_spend), 2) AS avg_ltv
FROM first_order_rating AS f INNER JOIN customer_ltv AS l ON f.customer_unique_id = l.customer_unique_id
WHERE f.order_rank = 1 AND f.review_score IN (1, 5)
GROUP BY f.review_score
ORDER BY f.review_score;

/*Insight: Customers who gave a 1-star review on their first order have a higher average lifetime value (199.13) compared to customers who gave a 5-star review (161.87).
This shows that higher spending customers are not always more satisfied.
Recommendation:Investigate high-spending customers who gave 1-star reviews and fix issues in their purchase experience.
Improve on service quality for high-value orders to reduce dissatisfaction and improve retention.*/

/* 17 Compare average freight costs and repeat purchase rates across key states (SP vs RJ)
to evaluate whether higher logistics costs are associated with lower customer retention. */

WITH customer_orders AS (SELECT O.order_id,C.customer_unique_id,C.customer_state,SUM(OI.freight_value) AS freight_value,
ROW_NUMBER() OVER (PARTITION BY C.customer_unique_id ORDER BY O.order_purchase_timestamp ASC) AS order_rank,O.order_purchase_timestamp
FROM orders AS O INNER JOIN order_items AS OI ON OI.order_id = O.order_id
INNER JOIN customers AS C ON C.customer_id = O.customer_id
WHERE o.order_status = 'delivered'
GROUP BY O.order_id,C.customer_unique_id,C.customer_state,O.order_purchase_timestamp)

SELECT customer_state,ROUND(AVG(freight_value),2) AS avg_freight, 
COUNT(DISTINCT CASE WHEN order_rank > 1 THEN customer_unique_id END) AS repeat_users, COUNT(DISTINCT customer_unique_id) AS total_users, 
ROUND(COUNT(DISTINCT CASE WHEN order_rank >1 THEN customer_unique_id END)* 100.0 / COUNT(DISTINCT customer_unique_id),2) AS repeated_user_pct
FROM customer_orders
WHERE customer_state IN ('SP','RJ')
GROUP BY customer_state;

/*Insight RJ shows higher average freight cost (23.95) compared to SP (17.33).
Repeat user percentage is almost similar in both states, RJ at 3.28% and SP at 3.13%, even though SP has a much larger customer base.

Recommendation: Track why RJ has higher freight cost (23.95) compared to SP and monitor its impact on cost efficiency.
Monitor repeat purchase levels in both states to maintain consistent customer return rates despite freight differences.*/

-- 18 At what time of day do customers place most orders?

SELECT EXTRACT(HOUR FROM order_purchase_timestamp) AS hour,COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY hour
ORDER BY hour;

/* Insight: Highest orders are at 16:00 (6476) and strong demand also at 11:00 and 14:00. 
Very lowest orders are at 05:00 (182) and 04:00 (203).
Recommendation: Focus business activity during peak hours like 11:00–16:00, 
and use early morning hours (04:00–05:00) for maintenance or low-activity tasks.*/

-- 19 What is the average time in hours for an order to be approved?

SELECT ROUND(AVG(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp)) / 3600),2) AS avg_approval_hours
FROM orders
WHERE order_approved_at IS NOT NULL;

/*Insight: The average order approval time is 10.42 hours from purchase to approval.
Recommendation: Check on reducing approval delays by reviewing internal approval process flow to improve overall order processing speed.*/

/*Q20 Which are the top 10 revenue-generating cities, and how does payment type 
(credit card, debit card, UPI, etc.) contribute to revenue distribution within those cities?*/

WITH city_data AS (SELECT g.city AS city,p.payment_type AS payment_type,SUM(p.payment_value) AS revenue
FROM orders AS o INNER JOIN customers AS c ON o.customer_id = c.customer_id INNER JOIN order_payments AS p ON o.order_id = p.order_id
INNER JOIN dim_geolocation AS g ON c.customer_zip_code_prefix = g.zip_code
WHERE o.order_status = 'delivered'
GROUP BY g.city, p.payment_type),

city_total AS (SELECT city,SUM(revenue) AS total_revenue
FROM city_data
GROUP BY city),

top_cities AS (SELECT city,total_revenue
FROM city_total
ORDER BY total_revenue DESC
LIMIT 10)

SELECT cd.city,cd.payment_type,cd.revenue,ct.total_revenue,ROUND(cd.revenue * 100.0 / ct.total_revenue, 2) AS payment_share_pct
FROM city_data AS cd INNER JOIN city_total AS ct ON cd.city = ct.city INNER JOIN top_cities AS tc ON cd.city = tc.city
ORDER BY ct.total_revenue DESC, cd.revenue DESC;

/* Insight: Credit card is the dominant payment method across all top cities and generates the highest revenue contribution.
Boleto is consistently the second most used payment method, while debit card and voucher contribute minimally across all cities.

Recommendations: Maintain the current payment structure since it already reflects stable customer behaviour across cities.
Use this breakdown as a baseline to track how payment preferences change over time in different regions.*/