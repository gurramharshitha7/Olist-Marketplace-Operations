-- ============================================================
-- QUERY 22: PRODUCT CATEGORY PERFORMANCE
-- Business Question:
-- Which product categories generate the highest order volume
-- and product value, and how do they compare in customer experience?
-- ============================================================

WITH category_order_details AS (
    SELECT
        p.product_category_name,
        o.order_id,
        SUM(oi.price) AS order_category_product_value,
        o.average_review_score,
        o.delivery_days,
        o.low_review_flag,
        o.investigation_score
    FROM dbo.olist_order_investigation AS o
    INNER JOIN dbo.olist_order_items_clean AS oi
        ON o.order_id = oi.order_id
    INNER JOIN dbo.olist_products_clean AS p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT NULL
    GROUP BY
        p.product_category_name,
        o.order_id,
        o.average_review_score,
        o.delivery_days,
        o.low_review_flag,
        o.investigation_score
)
SELECT
    product_category_name,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_category_product_value), 2) AS total_product_value,
    ROUND(SUM(order_category_product_value) / COUNT(*), 2) AS average_product_value_per_order,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(CAST(low_review_flag AS FLOAT)) * 100, 2) AS low_review_percentage,
    ROUND(AVG(CAST(investigation_score AS FLOAT)), 2) AS average_investigation_score
FROM category_order_details
GROUP BY product_category_name
ORDER BY total_product_value DESC;

-- ============================================================
-- QUERY 23: PRODUCT PRICE PATTERNS
-- Business Question:
-- How do different product price segments compare in customer experience,
-- delivery performance, and investigation risk?
-- ============================================================

SELECT
    CASE
        WHEN oi.price < 50 THEN 'Low Price'
        WHEN oi.price < 100 THEN 'Lower-Mid Price'
        WHEN oi.price < 250 THEN 'Mid Price'
        WHEN oi.price < 500 THEN 'Upper-Mid Price'
        ELSE 'High Price'
    END AS price_segment,
    COUNT(*) AS total_order_items,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS order_item_percentage,
    ROUND(AVG(oi.price), 2) AS average_product_price,
    ROUND(AVG(o.average_review_score), 2) AS average_review_score,
    ROUND(AVG(o.delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(CAST(o.low_review_flag AS FLOAT)) * 100, 2) AS low_review_percentage,
    ROUND(AVG(CAST(o.late_delivery_flag AS FLOAT)) * 100, 2) AS late_delivery_percentage,
    ROUND(AVG(CAST(o.severe_delay_flag AS FLOAT)) * 100, 2) AS severe_delay_percentage,
    ROUND(AVG(o.investigation_score), 2) AS average_investigation_score
FROM dbo.olist_order_items_clean AS oi
INNER JOIN dbo.olist_order_investigation AS o
    ON oi.order_id = o.order_id
GROUP BY
    CASE
        WHEN oi.price < 50 THEN 'Low Price'
        WHEN oi.price < 100 THEN 'Lower-Mid Price'
        WHEN oi.price < 250 THEN 'Mid Price'
        WHEN oi.price < 500 THEN 'Upper-Mid Price'
        ELSE 'High Price'
    END
ORDER BY
    CASE
        WHEN MIN(oi.price) < 50 THEN 1
        WHEN MIN(oi.price) < 100 THEN 2
        WHEN MIN(oi.price) < 250 THEN 3
        WHEN MIN(oi.price) < 500 THEN 4
        ELSE 5
    END;

-- ============================================================
-- QUERY 24: PRODUCT CHARACTERISTICS VS CUSTOMER EXPERIENCE
-- Business Question:
-- How do product weight categories compare in delivery performance,
-- customer reviews, and investigation risk?
-- ============================================================

SELECT
    CASE
        WHEN p.product_weight_g < 500 THEN 'Lightweight'
        WHEN p.product_weight_g < 2000 THEN 'Medium Weight'
        WHEN p.product_weight_g < 5000 THEN 'Heavyweight'
        ELSE 'Very Heavy'
    END AS weight_segment,
    COUNT(*) AS total_order_items,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS order_item_percentage,
    ROUND(AVG(p.product_weight_g), 2) AS average_product_weight_g,
    ROUND(AVG(oi.price), 2) AS average_product_price,
    ROUND(AVG(o.average_review_score), 2) AS average_review_score,
    ROUND(AVG(o.delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(CAST(o.low_review_flag AS FLOAT)) * 100, 2) AS low_review_percentage,
    ROUND(AVG(CAST(o.late_delivery_flag AS FLOAT)) * 100, 2) AS late_delivery_percentage,
    ROUND(AVG(CAST(o.severe_delay_flag AS FLOAT)) * 100, 2) AS severe_delay_percentage,
    ROUND(AVG(o.investigation_score), 2) AS average_investigation_score
FROM dbo.olist_order_items_clean AS oi
INNER JOIN dbo.olist_products_clean AS p
    ON oi.product_id = p.product_id
INNER JOIN dbo.olist_order_investigation AS o
    ON oi.order_id = o.order_id
WHERE p.product_weight_g IS NOT NULL
GROUP BY
    CASE
        WHEN p.product_weight_g < 500 THEN 'Lightweight'
        WHEN p.product_weight_g < 2000 THEN 'Medium Weight'
        WHEN p.product_weight_g < 5000 THEN 'Heavyweight'
        ELSE 'Very Heavy'
    END
ORDER BY
    CASE
        WHEN MIN(p.product_weight_g) < 500 THEN 1
        WHEN MIN(p.product_weight_g) < 2000 THEN 2
        WHEN MIN(p.product_weight_g) < 5000 THEN 3
        ELSE 4
    END;

-- ============================================================
-- QUERY 25: PRODUCT CATEGORIES LINKED TO OPERATIONAL ISSUES
-- Business Question:
-- Which product categories are most strongly associated with
-- delivery delays, severe delays, low customer reviews, and investigation risk?
-- ============================================================

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(AVG(o.delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(o.delivery_variance_days), 2) AS average_delivery_variance_days,
    ROUND(AVG(CAST(o.late_delivery_flag AS FLOAT)) * 100, 2) AS late_delivery_percentage,
    ROUND(AVG(CAST(o.severe_delay_flag AS FLOAT)) * 100, 2) AS severe_delay_percentage,
    ROUND(AVG(o.average_review_score), 2) AS average_review_score,
    ROUND(AVG(CAST(o.low_review_flag AS FLOAT)) * 100, 2) AS low_review_percentage,
    ROUND(AVG(CAST(o.investigation_score AS FLOAT)), 2) AS average_investigation_score
FROM dbo.olist_order_items_clean AS oi
INNER JOIN dbo.olist_products_clean AS p
    ON oi.product_id = p.product_id
INNER JOIN dbo.olist_order_investigation AS o
    ON oi.order_id = o.order_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY
    average_investigation_score DESC,
    late_delivery_percentage DESC,
    low_review_percentage DESC;
