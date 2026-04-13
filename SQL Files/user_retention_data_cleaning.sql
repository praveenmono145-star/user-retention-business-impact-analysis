-- CREATE DATABASE olist_db;

SELECT 'customers' AS table, COUNT(*) FROM raw_customers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM raw_geolocation
UNION ALL
SELECT 'order_items', COUNT(*) FROM raw_order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM raw_order_payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM raw_order_reviews
UNION ALL
SELECT 'orders', COUNT(*) FROM raw_orders
UNION ALL
SELECT 'product_transaltion', COUNT(*) FROM raw_product_category_name_translation
UNION ALL
SELECT 'product', COUNT(*) FROM raw_products
UNION ALL
SELECT 'sellers', COUNT(*) FROM raw_sellers;

-- checking without duplicates

SELECT 'customers' AS table, COUNT(*) FROM raw_customers
UNION 
SELECT 'geolocation', COUNT(*) FROM raw_geolocation
UNION 
SELECT 'order_items', COUNT(*) FROM raw_order_items
UNION 
SELECT 'payments', COUNT(*) FROM raw_order_payments
UNION 
SELECT 'reviews', COUNT(*) FROM raw_order_reviews
UNION 
SELECT 'orders', COUNT(*) FROM raw_orders
UNION 
SELECT 'product_transaltion', COUNT(*) FROM raw_product_category_name_translation
UNION 
SELECT 'product', COUNT(*) FROM raw_products
UNION 
SELECT 'sellers', COUNT(*) FROM raw_sellers;

-- -- -- Checking table structure 

SELECT table_name AS "Data table",column_name AS "Data Column",data_type AS "Data types"
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY "Data table";

-- validating null values 

SELECT order_id
FROM raw_order_payments 
WHERE order_id IS NULL;


SELECT payment_installments
FROM raw_order_payments 
WHERE payment_installments IS NULL;


SELECT shipping_limit_date
FROM raw_order_payments 
WHERE shipping_limit_date IS NULL;

SELECT review_comment_title
FROM raw_order_reviews 
WHERE review_comment_title  IS NULL;

SELECT table_name, column_name
FROM  information_schema.columns
WHERE table_schema ='public'
ORDER BY table_name;

SELECT order_id,COUNT(*) --  DUPLICATES 9803
FROM raw_order_items 
GROUP BY order_id
HAVING COUNT(*) >1;

SELECT order_id,COUNT(*) 0
FROM raw_orders
GROUP BY order_id
HAVING COUNT(*) >1;


SELECT order_id,COUNT(*) -- HV DUPLCATES 2961
FROM raw_order_payments
GROUP BY order_id
HAVING COUNT(*) >1;


SELECT order_id,COUNT(*) -- HV DUPLICATES 547
FROM raw_order_reviews
GROUP BY order_id
HAVING COUNT(*) >1;

-- RELATIONSHIP CHECKS
--- customer_id checks 

SELECT customer_id,COUNT(*) 
FROM raw_orders
GROUP BY customer_id
HAVING COUNT(*)>1; -- ZERO DUPLICATES VALUES

SELECT customer_id
FROM raw_orders
WHERE customer_id IS NULL; -- ZERO NULL

SELECT count(customer_id)
FROM raw_orders; -- 99441

SELECT COUNT(customer_id)
FROM raw_customers; -- 99441

SELECT customer_id
FROM raw_customers
WHERE customer_id IS NULL ; -- ZERO NULL

SELECT customer_id,COUNT(*)
FROM raw_customers
GROUP BY customer_id
HAVING COUNT(*)>1; -- ZERO DUPLICATES VALUES


SELECT C.customer_id, O.customer_id
FROM raw_customers AS C LEFT JOIN raw_orders AS O ON c.customer_id = O.customer_id
WHERE O.customer_id IS NULL; -- NO NULL VALUES 

SELECT C.customer_id, O.customer_id
FROM raw_customers AS C RIGHT JOIN raw_orders AS O ON c.customer_id = O.customer_id
WHERE C.customer_id = O.customer_id; -- NO NULL VALUES 

SELECT customer_id
FROM raw_customers AS C 
WHERE not EXISTS (SELECT customer_id
FROM raw_orders AS O
WHERE C.customer_id = O.customer_id
);

-- ===================order_id checks ================

SELECT order_id, COUNT(*)
FROM raw_order_reviews
GROUP BY order_id
HAVING COUNT(*)>1; -- HAVE DUPLICATES 547

SELECT order_id
FROM raw_order_reviews
WHERE order_id IS NULL; -- NO NULL

SELECT order_id, COUNT(*)
FROM raw_orders
GROUP BY order_id
HAVING COUNT(*)>1; -- NO DUPLICATES 


SELECT order_id
FROM raw_orders
WHERE order_id IS NULL; -- NO NULLS


SELECT order_id, COUNT(*)
FROM raw_order_items
GROUP BY order_id
HAVING COUNT(*)>1; -- 9803 Duplicates

SELECT order_id
FROM raw_order_items
WHERE order_id IS NULL; -- no nulls



SELECT order_id, COUNT(*)
FROM raw_order_payments
GROUP BY order_id
HAVING COUNT(*)>1; -- 2961 duplicates 


SELECT order_id
FROM raw_order_payments
WHERE order_id IS NULL; --  no nulls



-- === product_id checks

SELECT product_id, COUNT(*)
FROM raw_order_items
GROUP BY product_id
HAVING COUNT(*)>1; -- 14834 Duplicates

SELECT product_id
FROM raw_order_items
WHERE product_id IS NULL; -- no nulls

SELECT product_id, COUNT(*)
FROM raw_products
GROUP BY product_id
HAVING COUNT(*)>1;  -- no duplicates 

SELECT product_id
FROM raw_products
WHERE product_id IS NULL; -- no nulls


-- ============checks seller_id  =========

SELECT seller_id, COUNT(*)
FROM raw_order_items
GROUP BY seller_id
HAVING COUNT(*)>1; -- 2586 duplicates 


SELECT seller_id
FROM raw_order_items
WHERE seller_id IS NULL; -- no nulls 


-- ================ checks product_category_name  ===

SELECT product_category_name, COUNT(*)
FROM raw_product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*)>1;  -- no duplicates

SELECT product_category_name
FROM raw_product_category_name_translation
WHERE product_category_name IS NULL; -- no nulls


SELECT product_category_name, COUNT(*)
FROM raw_products
GROUP BY product_category_name
HAVING COUNT(*)>1; -- duplicates 73

SELECT product_category_name
FROM raw_products
WHERE product_category_name IS NULL; -- 610 nulls

-- === CHECKS customer_zip_code_prefix ---

SELECT customer_zip_code_prefix, COUNT(*)
FROM raw_customers
GROUP BY customer_zip_code_prefix
HAVING COUNT(*)>1;  -- DUPICATES  11982

SELECT customer_zip_code_prefix
FROM raw_customers
WHERE customer_zip_code_prefix IS NULL; -- NO NULLS

SELECT geolocation_zip_code_prefix, COUNT(*)
FROM raw_geolocation 
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*)>1;                -- DUPLICATES 17972

SELECT geolocation_zip_code_prefix
FROM raw_geolocation
WHERE geolocation_zip_code_prefix IS NULL; -- NO NULLS



SELECT seller_zip_code_prefix, COUNT(*)
FROM raw_sellers 
GROUP BY seller_zip_code_prefix
HAVING COUNT(*)>1; -- Duplicates 537

SELECT seller_zip_code_prefix
FROM raw_sellers
WHERE seller_zip_code_prefix IS NULL; -- no nulls



--=================


SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS unique_customers
FROM raw_orders; --99441 total rows and unique customers 99441

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS unique_customers
FROM raw_customers;  --99441 total rows and unique customers 99441

SELECT customer_unique_id, COUNT(*) AS total_orders
FROM raw_customers C
JOIN raw_orders O
ON C.customer_id = O.customer_id
GROUP BY customer_unique_id; -- this returns total rows mentioned in postgrlsql 96096 rows


SELECT customer_unique_id, COUNT(*) AS total_orders
FROM raw_customers C
JOIN raw_orders O
ON C.customer_id = O.customer_id
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

SELECT customer_unique_id, COUNT(*) 
FROM raw_customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;


-- =====================================creation new table ============================================================================================


-- raw_product_category_name_translation table 

CREATE TABLE product_category_name_translation AS SELECT 
product_category_name, 
product_category_name_english
FROM raw_product_category_name_translation;

-- raw_sellers table

CREATE TABLE sellers AS SELECT seller_id,
seller_city,seller_state,seller_zip_code_prefix
FROM raw_sellers;

--- raw_geolocation

CREATE TABLE geolocation AS SELECT
geolocation_zip_code_prefix,
geolocation_state,geolocation_city,
geolocation_lat,
geolocation_lng
FROM raw_geolocation
ORDER BY geolocation_zip_code_prefix,geolocation_city;

-- raw_customers

CREATE TABLE customers AS SELECT
customer_id,customer_unique_id,customer_state,
customer_city,customer_zip_code_prefix
FROM raw_customers;

-- raw_products

CREATE TABLE products AS SELECT 
product_id,product_category_name,
product_weight_g,product_width_cm,
product_length_cm,product_name_lenght,product_height_cm,
product_photos_qty,product_description_lenght
FROM raw_products;


-- raw_orders

CREATE TABLE orders AS SELECT
order_id,customer_id,order_status,
CAST(order_purchase_timestamp AS TIMESTAMP) AS order_purchase_timestamp,
CAST(order_approved_at AS TIMESTAMP) AS order_approved_at,
CAST(order_delivered_carrier_date AS TIMESTAMP) AS order_delivered_carrier_date,
CAST(order_delivered_customer_date AS TIMESTAMP) AS order_delivered_customer_date,
CAST(order_estimated_delivery_date AS TIMESTAMP) AS order_estimated_delivery_date
FROM raw_orders;

-- raw_order_items

CREATE TABLE order_items AS SELECT 
CAST(order_item_id AS INTEGER) AS order_item_id,
order_id,
product_id,
seller_id,
CAST(price AS DECIMAL(10,2)) AS price,
CAST(freight_value AS DECIMAL(10,2)) AS freight_value,
CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date
FROM raw_order_items;

-- raw_order_payments

CREATE TABLE order_payments AS SELECT 
order_id,
CAST(payment_value AS DECIMAL(10,2)) AS payment_value,
CAST(payment_sequential AS INTEGER) AS payment_sequential,
CAST(payment_installments AS INTEGER) AS payment_installments,
payment_type
FROM raw_order_payments;


-- raw_order_reviews

CREATE TABLE order_reviews AS SELECT
review_id,order_id,review_score,
CAST(review_creation_date AS TIMESTAMP) AS review_creation_date,
CAST(review_answer_timestamp AS TIMESTAMP) AS review_answer_timestamp,
review_comment_title,
review_comment_message
FROM raw_order_reviews;

-- Calendar table 

CREATE TABLE calender_table AS SELECT 
datum::date AS datekey,
EXTRACT(YEAR FROM datum)AS Year,
EXTRACT(MONTH FROM datum) AS Month,
TO_CHAR(datum,'Month') AS Month_name,
TO_CHAR(datum,'Day') AS Day_name,
'Q' || EXTRACT(QUARTER FROM datum) AS Quarter,
CASE WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type
FROM generate_series('2016-01-01'::date,
'2018-12-31'::date,
'1 day'::interval 
)datum;


select *
from calender_table;

-- ===================================== Cleaning Data ===============================================================================================================

CREATE EXTENSION IF NOT EXISTS unaccent;

SELECT *
FROM orders;

SELECT *
FROM order_items;

SELECT *
FROM ORDER_PAYMENT;

SELECT *
FROM order_reviews;

SELECT *
FROM product_category_name_translation;

SELECT *
FROM products;


-- ==============Replcing=====================
-- in this three values not exists null and "portateis_cozinha_e_preparadores_de_alimentos" and "pc_gamer"

SELECT DISTINCT p.product_category_name
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM product_category_name_translation t
    WHERE t.product_category_name = p.product_category_name);

INSERT INTO product_category_name_translation (product_category_name,product_category_name_english)
VALUES 
('portateis_cozinha_e_preparadores_de_alimentos','portable_kitchen_and_food_preparators'),
('pc_gamer','Gaming PC');

SELECT DISTINCT p.product_category_name
FROM products p
WHERE p.product_category_name IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM product_category_name_translation t
    WHERE t.product_category_name = p.product_category_name
);
--- ========================= Replacing nulls ======================================
-- replcing the nulls only for numeric columns 

-- product_category_name

INSERT INTO product_category_name_translation
VALUES ('Unknown','Unknown');

UPDATE products
SET product_category_name = 'Unknown'
WHERE product_category_name IS NULL;

SELECT *
FROM products
WHERE product_category_name = 'Unknown';

-- product_weight_g -- 2 NULLS

UPDATE products
SET product_weight_g = (SELECT AVG(product_weight_g)
FROM products)
WHERE product_weight_g IS NULL; 

-- product_width_cm -- 2 NULLS

UPDATE products
SET product_width_cm =(SELECT AVG(product_width_cm)
FROM products)
WHERE product_width_cm IS NULL;

-- product_height_cm -- 2 NULLS

UPDATE products
SET product_height_cm =(SELECT AVG(product_height_cm)
FROM products)
WHERE product_height_cm IS NULL;

-- product_length_cm -- 2 NULLS

UPDATE products
SET product_length_cm =(SELECT AVG(product_length_cm)
FROM products)
WHERE product_length_cm IS NULL;

-- ==================================================================================================================
-- text normalization only for geo location

SELECT *
FROM customers;
SELECT *
FROM GEOLOCATION;
SELECT *
FROM SELLERS;

-- checks before updating
SELECT geolocation_zip_code_prefix,LOWER(REGEXP_REPLACE(unaccent(geolocation_city, '[^a-zA-Z0-9 ]', '', 'g'))) AS geolocation_city
FROM geolocation;

-- add new columns 
ALTER TABLE geolocation
ADD COLUMN city_clean TEXT;
-- updating 
UPDATE geolocation
SET city_clean = LOWER(REGEXP_REPLACE(unaccent(geolocation_city),'[^a-zA-Z0-9 ]','','g'));

-- final checks
SELECT *
FROM geolocation
ORDER BY geolocation_zip_code_prefix;

-- ============data sanity checks========================

select count(customer_zip_code_prefix) --  99441
from customers;

select count(geolocation_zip_code_prefix)
from geolocation; -- 1000163

select count(seller_zip_code_prefix)
from sellers; -- 395

-- checks customers's zip codes not hv in geolocation

SELECT DISTINCT c.customer_zip_code_prefix
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM geolocation g
    WHERE g.geolocation_zip_code_prefix = c.customer_zip_code_prefix)
ORDER BY c.customer_zip_code_prefix;  -- TOTAL ROWS 157

-- checks sellers's zip codes not hv in geolocation

SELECT DISTINCT s.seller_zip_code_prefix
FROM sellers s
WHERE NOT EXISTS (
    SELECT 1 
    FROM geolocation g
    WHERE g.geolocation_zip_code_prefix = s.seller_zip_code_prefix)
ORDER BY s.seller_zip_code_prefix; -- 7 rows

-- checks geolocation's zip codes not hv in customers

SELECT DISTINCT g.geolocation_zip_code_prefix
FROM geolocation g
WHERE NOT EXISTS (
    SELECT 1
    FROM customers c
    WHERE c.customer_zip_code_prefix = g.geolocation_zip_code_prefix)
ORDER BY g.geolocation_zip_code_prefix; -- 4178

-- checks geolocation's zip codes not hv in sellers

SELECT DISTINCT g.geolocation_zip_code_prefix
FROM geolocation g
WHERE NOT EXISTS (
    SELECT 1
    FROM sellers s
    WHERE s.seller_zip_code_prefix = g.geolocation_zip_code_prefix)
ORDER BY g.geolocation_zip_code_prefix; --16776

-- dim zip code ----
-- union three tables 

CREATE TABLE dim_location_master_zips AS 

SELECT geolocation_zip_code_prefix AS zip_code FROM geolocation
UNION -- UNION automatically removes duplicates
SELECT customer_zip_code_prefix FROM customers
UNION 
SELECT seller_zip_code_prefix FROM sellers;

SELECT *
FROM dim_location_master_zips;

-- creating the uniqueless table 

CREATE  TABLE aggregate_location AS SELECT 
    geolocation_zip_code_prefix AS zip,
    AVG(geolocation_lat) AS lat,
    AVG(geolocation_lng) AS lng,
    MAX(city_clean) AS city,
    MAX(geolocation_state) AS state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

-- join both tables to validate 

SELECT a.zip_code ,g.lat,g.lng,g.city,g.state
FROM dim_location_master_zips a
LEFT JOIN aggregate_location g
ON a.zip_code = g.zip
ORDER BY a.zip_code;

-- create the final geo location table 

CREATE TABLE dim_geolocation AS
SELECT M.zip_code
,G.lat AS latitude
,G.lng AS longitude
,G.city
,G.state
FROM dim_location_master_zips AS M LEFT JOIN aggregate_location AS G ON M.zip_code = G.zip
ORDER BY M.zip_code;

SELECT *
FROM dim_geolocation
WHERE latitude IS NULL; -- Total null rows 162

SELECT *
FROM dim_geolocation
WHERE longitude IS NULL; -- Total null rows 162

-------------------------Updating null values---------------------------------
UPDATE dim_geolocation
SET  latitude = 0,
longitude = 0
WHERE latitude IS NULL;

UPDATE dim_geolocation
SET city = 'Unknown'
WHERE city IS NULL;

UPDATE dim_geolocation
SET state = 'N/A'
WHERE state IS NULL;

SELECT *
FROM dim_geolocation
WHERE state =  'N/A' ;



--- =========================================Primary keys ==========================================================================================================

ALTER TABLE product_category_name_translation
ADD PRIMARY KEY (product_category_name);

ALTER TABLE orders
ADD PRIMARY KEY (order_id);

ALTER TABLE products
ADD PRIMARY KEY (product_id);

ALTER TABLE customers
ADD PRIMARY KEY (customer_id);

ALTER TABLE sellers
ADD PRIMARY KEY (seller_id);

ALTER TABLE dim_geolocation 
ADD PRIMARY KEY (zip_code);

ALTER TABLE calender_table 
ADD PRIMARY KEY (datekey);

--========================================= foreign keys =================================================================

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_product FOREIGN KEY(product_id) REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_sellers FOREIGN KEY(seller_id) REFERENCES sellers(seller_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders FOREIGN KEY(customer_id) REFERENCES customers(customer_id);

ALTER TABLE products
ADD CONSTRAINT fk_products FOREIGN KEY(product_category_name) REFERENCES product_category_name_translation
(product_category_name);

ALTER TABLE order_reviews
ADD CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_payments
ADD CONSTRAINT fk_payment FOREIGN KEY(order_id) REFERENCES orders(order_id);

ALTER TABLE customers 
ADD CONSTRAINT fk_cus_zip FOREIGN KEY(customer_zip_code_prefix) REFERENCES dim_geolocation(zip_code);

ALTER TABLE sellers
ADD CONSTRAINT fk_sell_zip FOREIGN KEY(seller_zip_code_prefix) REFERENCES dim_geolocation(zip_code);

--================= INDEX CREATION =========================================================================
-- order_items
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- order_payments
CREATE INDEX idx_order_payments_order ON order_payments(order_id);

-- order_reviews
CREATE INDEX idx_order_reviews_order ON order_reviews(order_id);

-- customers
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- customer_unique_id
CREATE INDEX idx_customers_unique_id ON customers (customer_unique_id);