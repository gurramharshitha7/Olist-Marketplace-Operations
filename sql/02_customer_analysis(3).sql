-- ============================================================
-- QUERY 8: CUSTOMER SEGMENTATION
-- Business Question:
-- How is the customer base distributed between repeat and one-time customers?
-- ============================================================

SELECT
    CASE
        WHEN total_orders > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END AS customer_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(total_spend), 2) AS average_customer_spend,
    ROUND(AVG(avg_order_value), 2) AS average_order_value
FROM dbo.olist_customer_investigation
GROUP BY
    CASE
        WHEN total_orders > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END
ORDER BY total_customers DESC;

-- ============================================================
-- QUERY 9: CUSTOMER SPENDING PATTERNS
-- Business Question:
-- How is customer spending distributed across different spending levels?
-- ============================================================

SELECT
    CASE
        WHEN total_spend < 100 THEN 'Low Spending'
        WHEN total_spend < 300 THEN 'Medium Spending'
        WHEN total_spend < 700 THEN 'High Spending'
        ELSE 'Very High Spending'
    END AS spending_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(total_spend), 2) AS average_total_spend,
    ROUND(AVG(total_orders), 2) AS average_orders,
    ROUND(AVG(avg_order_value), 2) AS average_order_value
FROM dbo.olist_customer_investigation
GROUP BY
    CASE
        WHEN total_spend < 100 THEN 'Low Spending'
        WHEN total_spend < 300 THEN 'Medium Spending'
        WHEN total_spend < 700 THEN 'High Spending'
        ELSE 'Very High Spending'
    END
ORDER BY average_total_spend;

-- ============================================================
-- QUERY 10: HIGH-VALUE CUSTOMERS
-- Business Question:
-- Who are the high-value customers, and how do they compare with the overall customer base?
-- ============================================================

SELECT
    CASE
        WHEN high_value_orders > 0 THEN 'High-Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(total_spend), 2) AS average_total_spend,
    ROUND(AVG(total_orders), 2) AS average_orders,
    ROUND(AVG(avg_order_value), 2) AS average_order_value,
    ROUND(AVG(avg_investigation_score), 2) AS average_investigation_score
FROM dbo.olist_customer_investigation
GROUP BY
    CASE
        WHEN high_value_orders > 0 THEN 'High-Value Customer'
        ELSE 'Regular Customer'
    END
ORDER BY average_total_spend DESC;

-- ============================================================
-- QUERY 11: LOW-REVIEW CUSTOMERS
-- Business Question:
-- Which customers experience consistently poor satisfaction
-- based on their order reviews?
-- ============================================================

SELECT
    CASE
        WHEN low_review_orders > 0 THEN 'Low-Review Customer'
        ELSE 'No Low-Review History'
    END AS customer_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(avg_review_score), 2) AS average_review_score,
    ROUND(AVG(low_review_orders), 2) AS average_low_review_orders,
    ROUND(AVG(total_spend), 2) AS average_total_spend,
    ROUND(AVG(avg_investigation_score), 2) AS average_investigation_score
FROM dbo.olist_customer_investigation
GROUP BY
    CASE
        WHEN low_review_orders > 0 THEN 'Low-Review Customer'
        ELSE 'No Low-Review History'
    END
ORDER BY average_review_score;

-- ============================================================
-- QUERY 12: CUSTOMERS WITH REPEATED DELIVERY ISSUES
-- Business Question:
-- How many customers experience repeated delivery issues,
-- and how severe are those issues?
-- ============================================================

SELECT
    CASE
        WHEN late_orders >= 2 THEN 'Repeated Delivery Issues'
        WHEN late_orders = 1 THEN 'Single Delivery Issue'
        ELSE 'No Recorded Delivery Issue'
    END AS delivery_issue_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(late_orders), 2) AS average_late_orders,
    ROUND(AVG(severe_delay_orders), 2) AS average_severe_delay_orders,
    ROUND(AVG(avg_delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(avg_investigation_score), 2) AS average_investigation_score
FROM dbo.olist_customer_investigation
GROUP BY
    CASE
        WHEN late_orders >= 2 THEN 'Repeated Delivery Issues'
        WHEN late_orders = 1 THEN 'Single Delivery Issue'
        ELSE 'No Recorded Delivery Issue'
    END
ORDER BY average_late_orders DESC;

-- ============================================================
-- QUERY 13: CUSTOMER INVESTIGATION PRIORITY
-- Business Question:
-- How are customers distributed across investigation risk levels?
-- ============================================================

SELECT
    CASE
        WHEN high_priority_cases > 0 THEN 'High Priority'
        WHEN avg_investigation_score >= 1 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END AS investigation_priority,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(avg_investigation_score), 2) AS average_investigation_score,
    ROUND(AVG(total_spend), 2) AS average_total_spend,
    ROUND(AVG(late_orders), 2) AS average_late_orders,
    ROUND(AVG(low_review_orders), 2) AS average_low_review_orders
FROM dbo.olist_customer_investigation
GROUP BY
    CASE
        WHEN high_priority_cases > 0 THEN 'High Priority'
        WHEN avg_investigation_score >= 1 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END
ORDER BY average_investigation_score DESC;

-- ============================================================
-- QUERY 14: GEOGRAPHIC CUSTOMER PATTERNS
-- Business Question:
-- How do customer behaviour and spending patterns vary
-- across different states?
-- ============================================================

SELECT
    customer_state,
    COUNT(*) AS total_customers,
    ROUND(AVG(total_orders), 2) AS average_orders_per_customer,
    ROUND(AVG(total_spend), 2) AS average_customer_spend,
    ROUND(AVG(avg_order_value), 2) AS average_order_value,
    ROUND(AVG(late_order_rate) * 100, 2) AS late_order_percentage,
    ROUND(AVG(low_review_rate) * 100, 2) AS low_review_percentage,
    ROUND(AVG(avg_investigation_score), 2) AS average_investigation_score
FROM dbo.olist_customer_investigation
GROUP BY customer_state
ORDER BY average_customer_spend DESC;
