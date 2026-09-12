-- ============================================================
-- QUERY 15: TOP SELLERS BY REVENUE AND ORDERS
-- Business Question:
-- Which sellers generate the highest product value and handle
-- the highest number of orders?
-- ============================================================

SELECT TOP 10
    seller_id,
    orders_handled,
    total_product_value,
    total_freight_value,
    ROUND(total_product_value / NULLIF(orders_handled, 0), 2) AS average_product_value_per_order,
    ROUND(avg_delivery_days, 2) AS average_delivery_days,
    ROUND(avg_review_score, 2) AS average_review_score
FROM dbo.olist_seller_investigation
ORDER BY
    total_product_value DESC,
    orders_handled DESC;

-- ============================================================
-- QUERY 16: SELLERS WITH POOR DELIVERY PERFORMANCE
-- Business Question:
-- Which sellers have the poorest delivery performance based on
-- late delivery rates and delivery duration?
-- ============================================================

SELECT TOP 10
    seller_id,
    orders_handled,
    ROUND(avg_delivery_days, 2) AS average_delivery_days,
    late_orders,
    severe_delay_orders,
    ROUND(late_delivery_rate * 100, 2) AS late_delivery_percentage,
    ROUND(severe_delay_rate * 100, 2) AS severe_delay_percentage,
    ROUND(avg_delivery_variance_days, 2) AS average_delivery_variance_days,
    ROUND(avg_investigation_score, 2) AS average_investigation_score
FROM dbo.olist_seller_investigation
WHERE orders_handled >= 10
ORDER BY
    late_delivery_rate DESC,
    severe_delay_rate DESC,
    avg_delivery_days DESC;

-- ============================================================
-- QUERY 17: SELLERS WITH LOW CUSTOMER REVIEW SCORES
-- Business Question:
-- Which sellers have the poorest customer review performance?
-- ============================================================

SELECT TOP 10
    seller_id,
    orders_handled,
    ROUND(avg_review_score, 2) AS average_review_score,
    low_review_orders,
    ROUND(low_review_rate * 100, 2) AS low_review_percentage,
    ROUND(avg_delivery_days, 2) AS average_delivery_days,
    ROUND(late_delivery_rate * 100, 2) AS late_delivery_percentage,
    ROUND(avg_investigation_score, 2) AS average_investigation_score
FROM dbo.olist_seller_investigation
WHERE orders_handled >= 10
ORDER BY
    avg_review_score,
    low_review_rate DESC,
    orders_handled DESC;

-- ============================================================
-- QUERY 18: HIGH-RISK SELLERS
-- Business Question:
-- Which sellers show multiple operational and customer experience risk indicators?
-- ============================================================

SELECT TOP 10
    seller_id,
    orders_handled,
    ROUND(avg_investigation_score, 2) AS average_investigation_score,
    late_orders,
    severe_delay_orders,
    low_review_orders,
    ROUND(late_delivery_rate * 100, 2) AS late_delivery_percentage,
    ROUND(severe_delay_rate * 100, 2) AS severe_delay_percentage,
    ROUND(low_review_rate * 100, 2) AS low_review_percentage,
    ROUND(avg_review_score, 2) AS average_review_score,
    ROUND(avg_delivery_days, 2) AS average_delivery_days
FROM dbo.olist_seller_investigation
WHERE orders_handled >= 10
  AND avg_investigation_score > 0
ORDER BY
    avg_investigation_score DESC,
    low_review_rate DESC,
    late_delivery_rate DESC;

-- ============================================================
-- QUERY 19: SELLER INVESTIGATION PRIORITY
-- Business Question:
-- How are established sellers distributed across investigation priority levels based on their average investigation score?
-- ============================================================

SELECT
    CASE
        WHEN avg_investigation_score >= 2 THEN 'High Priority'
        WHEN avg_investigation_score > 0 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END AS investigation_priority,
    COUNT(*) AS total_sellers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS seller_percentage,
    ROUND(AVG(avg_investigation_score), 2) AS average_investigation_score,
    ROUND(AVG(orders_handled), 2) AS average_orders_handled,
    ROUND(AVG(late_delivery_rate) * 100, 2) AS average_late_delivery_percentage,
    ROUND(AVG(low_review_rate) * 100, 2) AS average_low_review_percentage
FROM dbo.olist_seller_investigation
WHERE orders_handled >= 10
GROUP BY
    CASE
        WHEN avg_investigation_score >= 2 THEN 'High Priority'
        WHEN avg_investigation_score > 0 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END
ORDER BY average_investigation_score DESC;

-- ============================================================
-- QUERY 20: MULTI-SELLER OPERATIONAL COMPLEXITY
-- Business Question:
-- Do orders involving multiple sellers show worse delivery
-- performance and customer experience?
-- ============================================================

SELECT
    CASE
        WHEN unique_sellers > 1 THEN 'Multi-Seller Order'
        ELSE 'Single-Seller Order'
    END AS order_complexity,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS order_percentage,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(delivery_variance_days), 2) AS average_delivery_variance_days,
    ROUND(AVG(CAST(late_delivery_flag AS FLOAT)) * 100, 2) AS late_delivery_percentage,
    ROUND(AVG(CAST(severe_delay_flag AS FLOAT)) * 100, 2) AS severe_delay_percentage,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(total_payment_value), 2) AS average_order_value,
    ROUND(AVG(investigation_score), 2) AS average_investigation_score
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered'
GROUP BY
    CASE
        WHEN unique_sellers > 1 THEN 'Multi-Seller Order'
        ELSE 'Single-Seller Order'
    END
ORDER BY average_investigation_score DESC;

-- ============================================================
-- QUERY 21: SELLER PERFORMANCE COMPARISON
-- Business Question:
-- Which established sellers show the strongest overall performance
-- across customer satisfaction, delivery reliability, investigation
-- risk, and operational scale?
-- ============================================================

SELECT TOP 10
    seller_id,
    orders_handled,
    ROUND(avg_review_score, 2) AS average_review_score,
    ROUND(avg_delivery_days, 2) AS average_delivery_days,
    ROUND(late_delivery_rate * 100, 2) AS late_delivery_percentage,
    ROUND(avg_investigation_score, 2) AS average_investigation_score
FROM dbo.olist_seller_investigation
WHERE orders_handled >= 50
ORDER BY
    avg_review_score DESC,
    late_delivery_rate,
    avg_investigation_score,
    orders_handled DESC;
