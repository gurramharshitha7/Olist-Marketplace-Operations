/*
Project: Olist E-commerce Data Quality & Exception Analysis
Database: MS SQL Server
Main table: dbo.olist_order_investigation

Purpose:
- Validate data completeness and consistency
- Identify and investigate exceptions
- Tune rules to reduce false positives
- Produce a simple exception report for business users
- Monitor day-over-day order volume volatility

Final DoD Monitoring Rule:
- Flag day-over-day order volume changes of >= 30%
- Require previous-day order volume >= 50
- Treat alerts as investigation candidates, not confirmed data-quality errors
*/

-- ============================================================
-- 1. MISSING ORDER IDs
-- Rule: Every order should have an order ID
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_ids
FROM dbo.olist_order_investigation;


-- ============================================================
-- 2. DUPLICATE ORDER IDs
-- Rule: Each order ID should appear only once
-- ============================================================

SELECT
    order_id,
    COUNT(*) AS record_count
FROM dbo.olist_order_investigation
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. MISSING CUSTOMER IDs
-- Rule: Every order should have a customer ID
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_ids
FROM dbo.olist_order_investigation;


-- ============================================================
-- 4. MISSING PURCHASE DATES
-- Rule: Every order should have a purchase date
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)
        AS missing_purchase_dates
FROM dbo.olist_order_investigation;


-- ============================================================
-- 5. VALID ORDER STATUS
-- Rule: Order status must be one of the approved values
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN order_status NOT IN (
                'delivered',
                'shipped',
                'canceled',
                'unavailable',
                'invoiced',
                'processing',
                'created',
                'approved'
            )
            OR order_status IS NULL
            THEN 1
            ELSE 0
        END
    ) AS invalid_status_records
FROM dbo.olist_order_investigation;


-- Optional: review the actual status values
SELECT
    order_status,
    COUNT(*) AS record_count
FROM dbo.olist_order_investigation
GROUP BY order_status
ORDER BY record_count DESC;


-- ============================================================
-- 6. PAYMENT VALUE CHECK
-- Rule: Payment value should not be negative
-- Also investigate zero-payment orders
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN total_payment_value < 0 THEN 1 ELSE 0 END)
        AS negative_payment_values,
    SUM(CASE WHEN total_payment_value = 0 THEN 1 ELSE 0 END)
        AS zero_payment_values
FROM dbo.olist_order_investigation;


-- Investigate zero-payment orders
SELECT
    order_id,
    order_status,
    total_payment_value,
    total_product_value,
    total_freight_value,
    total_items
FROM dbo.olist_order_investigation
WHERE total_payment_value = 0;


-- Refined rule:
-- A zero-payment order is flagged only when it is NOT canceled.
SELECT
    COUNT(*) AS true_exceptions
FROM dbo.olist_order_investigation
WHERE total_payment_value = 0
  AND (order_status <> 'canceled' OR order_status IS NULL);


-- ============================================================
-- 7. DELIVERY DATE CONSISTENCY
-- Rule: Customer delivery date cannot be before purchase date
-- ============================================================

SELECT
    COUNT(*) AS invalid_delivery_dates
FROM dbo.olist_order_investigation
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;


-- ============================================================
-- 8. DELIVERED ORDERS MISSING DELIVERY DATE
-- Rule: A delivered order should have a customer delivery date
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,
    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 1
            ELSE 0
        END
    ) AS delivered_without_delivery_date
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered';


-- Investigate the exceptions
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    delivery_days,
    delivery_variance_days,
    late_delivery_flag,
    severe_delay_flag
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- Impact of the exceptions
SELECT
    COUNT(*) AS exception_count,
    SUM(CASE WHEN delivery_days IS NULL THEN 1 ELSE 0 END)
        AS missing_delivery_days,
    SUM(CASE WHEN delivery_variance_days IS NULL THEN 1 ELSE 0 END)
        AS missing_delivery_variance
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- ============================================================
-- 9. EXCEPTION REPORT
-- Business output: records that need investigation
-- ============================================================

SELECT
    order_id,
    'DQ-DELIVERY-001' AS rule_id,
    'Delivered Order Missing Customer Delivery Date' AS rule_name,
    'Missing delivery timestamp' AS exception,
    'Medium' AS severity,
    'Delivery duration and delivery variance cannot be reliably calculated'
        AS business_impact,
    'Investigate source delivery-date data before using delivery metrics'
        AS recommended_action
FROM dbo.olist_order_investigation
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL
ORDER BY order_id;


-- ============================================================
-- 10. DATA QUALITY RULE LOG
-- Summary of validation results
-- ============================================================

SELECT
    'DQ-ORDER-001' AS rule_id,
    'Missing Order ID' AS rule_name,
    COUNT(*) AS records_checked,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS exceptions,
    'No action required' AS action_taken
FROM dbo.olist_order_investigation

UNION ALL

SELECT
    'DQ-ORDER-002',
    'Duplicate Order ID',
    (SELECT COUNT(*) FROM dbo.olist_order_investigation),
    (
        SELECT COUNT(*)
        FROM (
            SELECT order_id
            FROM dbo.olist_order_investigation
            GROUP BY order_id
            HAVING COUNT(*) > 1
        ) AS duplicates
    ),
    'No action required'

UNION ALL

SELECT
    'DQ-ORDER-003',
    'Missing Customer ID',
    COUNT(*),
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END),
    'No action required'
FROM dbo.olist_order_investigation

UNION ALL

SELECT
    'DQ-ORDER-004',
    'Missing Purchase Date',
    COUNT(*),
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END),
    'No action required'
FROM dbo.olist_order_investigation

UNION ALL

SELECT
    'DQ-ORDER-005',
    'Invalid Order Status',
    COUNT(*),
    SUM(
        CASE
            WHEN order_status NOT IN (
                'delivered',
                'shipped',
                'canceled',
                'unavailable',
                'invoiced',
                'processing',
                'created',
                'approved'
            )
            OR order_status IS NULL
            THEN 1
            ELSE 0
        END
    ),
    'No action required'
FROM dbo.olist_order_investigation

UNION ALL

SELECT
    'DQ-PAYMENT-001',
    'Zero Payment Value After Rule Tuning',
    COUNT(*),
    SUM(
        CASE
            WHEN total_payment_value = 0
                 AND order_status <> 'canceled'
            THEN 1
            ELSE 0
        END
    ),
    '3 initial flags reviewed; all were legitimate canceled orders'
FROM dbo.olist_order_investigation

UNION ALL

SELECT
    'DQ-DELIVERY-001',
    'Delivered Order Missing Customer Delivery Date',
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END),
    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NULL
            THEN 1
            ELSE 0
        END
    ),
    'Investigate source delivery-date data'
FROM dbo.olist_order_investigation;


-- ============================================================
-- 11. FINAL PROJECT SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NULL
            THEN 1
            ELSE 0
        END
    ) AS genuine_exceptions,
    3 AS initially_flagged_false_positives,
    'Delivered orders with missing customer delivery timestamps'
        AS primary_exception,
    'Delivery duration and variance metrics affected'
        AS business_impact
FROM dbo.olist_order_investigation;

-- ============================================================
-- 12. BASELINE DAY-OVER-DAY MONITORING
-- ============================================================
-- Initial monitoring rule using a 20% threshold.
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT order_date, order_count, previous_day_orders,
       ROUND(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0), 2) AS dod_change_pct,
       CASE WHEN ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 20
            THEN 'Exception' ELSE 'Normal' END AS anomaly_flag
FROM daily_changes
WHERE previous_day_orders IS NOT NULL
ORDER BY order_date;

-- ============================================================
-- 13. BASELINE DAY-OVER-DAY EXCEPTION COUNT
-- ============================================================
-- Baseline result used to evaluate alert volume before tuning.
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT
    COUNT(*) AS days_checked,
    SUM(CASE WHEN ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 20 THEN 1 ELSE 0 END) AS exceptions,
    ROUND(100.0 * SUM(CASE WHEN ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 20 THEN 1 ELSE 0 END) / COUNT(*), 2) AS exception_rate
FROM daily_changes
WHERE previous_day_orders IS NOT NULL;

-- ============================================================
-- 14. DAY-OVER-DAY THRESHOLD COMPARISON
-- ============================================================
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
),
changes AS (
    SELECT ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) AS change_pct
    FROM daily_changes
    WHERE previous_day_orders IS NOT NULL
)
SELECT 10 AS threshold_pct, SUM(CASE WHEN change_pct >= 10 THEN 1 ELSE 0 END) AS exceptions FROM changes
UNION ALL
SELECT 20, SUM(CASE WHEN change_pct >= 20 THEN 1 ELSE 0 END) FROM changes
UNION ALL
SELECT 30, SUM(CASE WHEN change_pct >= 30 THEN 1 ELSE 0 END) FROM changes
UNION ALL
SELECT 40, SUM(CASE WHEN change_pct >= 40 THEN 1 ELSE 0 END) FROM changes;

-- ============================================================
-- 15. INVESTIGATION OF 30% DAY-OVER-DAY ALERTS
-- ============================================================
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT TOP 20
    order_date,
    order_count,
    previous_day_orders,
    ROUND(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0), 2) AS dod_change_pct
FROM daily_changes
WHERE previous_day_orders IS NOT NULL
  AND ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
ORDER BY ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) DESC;

-- ============================================================
-- 16. FINAL DAY-OVER-DAY MONITORING RULE
-- Rule: Flag changes >= 30% when previous-day volume >= 50
-- ============================================================
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT
    order_date,
    order_count,
    previous_day_orders,
    ROUND(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0), 2) AS dod_change_pct,
    CASE
        WHEN ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
         AND previous_day_orders >= 50
        THEN 'Exception'
        ELSE 'Normal'
    END AS anomaly_flag
FROM daily_changes
WHERE previous_day_orders IS NOT NULL
ORDER BY order_date;

WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT
    COUNT(*) AS days_checked,
    SUM(CASE WHEN ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
        AND previous_day_orders >= 50 THEN 1 ELSE 0 END) AS exceptions
FROM daily_changes
WHERE previous_day_orders IS NOT NULL;

-- ============================================================
-- 17. FINAL DAY-OVER-DAY EXCEPTION REPORT
-- ============================================================
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT
    order_date,
    order_count,
    previous_day_orders,
    ROUND(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0), 2) AS dod_change_pct,
    'Exception' AS anomaly_flag
FROM daily_changes
WHERE previous_day_orders IS NOT NULL
  AND ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
  AND previous_day_orders >= 50
ORDER BY order_date;

-- ============================================================
-- 18. DAY-OVER-DAY EXCEPTION SUMMARY
-- ============================================================
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT
    COUNT(*) AS total_exceptions,
    SUM(CASE WHEN order_count > previous_day_orders THEN 1 ELSE 0 END) AS increase_exceptions,
    SUM(CASE WHEN order_count < previous_day_orders THEN 1 ELSE 0 END) AS decrease_exceptions,
    MAX(ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0))) AS largest_change_pct
FROM daily_changes
WHERE previous_day_orders IS NOT NULL
  AND ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
  AND previous_day_orders >= 50;

-- ============================================================
-- 19. DAY-OVER-DAY BUSINESS IMPACT CLASSIFICATION
-- ============================================================
WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
)
SELECT
    order_date,
    order_count,
    previous_day_orders,
    ROUND(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0), 2) AS dod_change_pct,
    CASE
        WHEN ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 100
            THEN 'High Volatility'
        WHEN order_count > previous_day_orders
            THEN 'Increase'
        ELSE 'Decrease'
    END AS impact_type
FROM daily_changes
WHERE previous_day_orders IS NOT NULL
  AND ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
  AND previous_day_orders >= 50
ORDER BY ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) DESC;

-- ============================================================
-- 20. FINAL DAY-OVER-DAY MONITORING SUMMARY
-- ============================================================

WITH daily_orders AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS order_date, COUNT(*) AS order_count
    FROM dbo.olist_order_investigation
    GROUP BY CAST(order_purchase_timestamp AS DATE)
),
daily_changes AS (
    SELECT order_date, order_count, LAG(order_count) OVER (ORDER BY order_date) AS previous_day_orders
    FROM daily_orders
),
exceptions AS (
    SELECT
        order_date,
        order_count,
        previous_day_orders,
        100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0) AS change_pct
    FROM daily_changes
    WHERE previous_day_orders IS NOT NULL
      AND ABS(100.0 * (order_count - previous_day_orders) / NULLIF(previous_day_orders, 0)) >= 30
      AND previous_day_orders >= 50
)
SELECT
    (SELECT COUNT(*) FROM daily_changes WHERE previous_day_orders IS NOT NULL) AS days_checked,
    COUNT(*) AS total_exceptions,
    SUM(CASE WHEN change_pct > 0 THEN 1 ELSE 0 END) AS increase_exceptions,
    SUM(CASE WHEN change_pct < 0 THEN 1 ELSE 0 END) AS decrease_exceptions,
    SUM(CASE WHEN ABS(change_pct) >= 100 THEN 1 ELSE 0 END) AS high_volatility_exceptions,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM daily_changes WHERE previous_day_orders IS NOT NULL), 0), 2) AS exception_rate
FROM exceptions;