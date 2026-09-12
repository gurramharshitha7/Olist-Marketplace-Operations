-- ============================================================
-- QUERY 1: ORDER STATUS DISTRIBUTION
-- Business Question:
-- What is the distribution of orders across different statuses?
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS order_percentage
FROM dbo.olist_order_investigation
GROUP BY order_status
ORDER BY total_orders DESC;

-- ============================================================
-- QUERY 2: MONTHLY ORDER VOLUME TREND
-- Business Question:
-- How did marketplace order volume change over time?
-- ============================================================

SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM dbo.olist_order_investigation
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;

-- ============================================================
-- QUERY 3: MONTHLY ORDER VALUE TREND
-- Business Question:
-- How did total marketplace payment value and average order
-- value change over time?
-- ============================================================

SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_payment_value), 2) AS total_payment_value,
    ROUND(AVG(total_payment_value), 2) AS average_order_value
FROM dbo.olist_order_investigation
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;

-- ============================================================
-- QUERY 4: DELIVERY PERFORMANCE OVERVIEW
-- Business Question:
-- What was the overall delivery performance for delivered orders?
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(delivery_variance_days), 2) AS average_delivery_variance_days,
    SUM(CAST(late_delivery_flag AS INT)) AS late_orders,
    ROUND(
        100.0 * SUM(CAST(late_delivery_flag AS INT)) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered';

-- ============================================================
-- QUERY 5: STATES WITH THE HIGHEST LATE DELIVERY RATE
-- Business Question:
-- Which customer states experience the highest proportion of late deliveries?
-- ============================================================

SELECT
    customer_state,
    COUNT(*) AS total_delivered_orders,
    SUM(CAST(late_delivery_flag AS INT)) AS late_orders,
    ROUND(
        100.0 * SUM(CAST(late_delivery_flag AS INT)) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered'
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY
    late_delivery_rate DESC,
    total_delivered_orders DESC;

-- ============================================================
-- QUERY 6: INVESTIGATION PRIORITY DISTRIBUTION
-- Business Question:
-- How are orders distributed across investigation priority levels?
-- ============================================================

SELECT
    investigation_priority,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS order_percentage,
    ROUND(AVG(investigation_score), 2) AS average_investigation_score
FROM dbo.olist_order_investigation
GROUP BY investigation_priority
ORDER BY
    CASE investigation_priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;

-- ============================================================
-- QUERY 7: HIGH-PRIORITY ORDER INVESTIGATION CASES
-- Business Question:
-- Which orders require investigation based on multiple operational
-- and customer experience risk indicators?
-- ============================================================

SELECT
    order_id,
    customer_unique_id,
    order_status,
    total_payment_value,
    payment_records,
    unique_sellers,
    delivery_variance_days,
    average_review_score,
    high_value_flag,
    late_delivery_flag,
    severe_delay_flag,
    low_review_flag,
    multiple_payment_flag,
    multiple_seller_flag,
    investigation_score,
    investigation_priority
FROM dbo.olist_order_investigation
WHERE investigation_priority = 'High'
ORDER BY
    investigation_score DESC,
    total_payment_value DESC;
