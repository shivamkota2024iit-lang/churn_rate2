-- ==============================================================================
-- PROJECT: Telco Customer Churn - Data Engineering & Analytics Pipeline
-- PURPOSE: Schema creation, Bulk data ingestion, and Advanced Churn Analytics
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PHASE 1: SCHEMA CREATION
-- ------------------------------------------------------------------------------
CREATE TABLE dim_accounts (
    customer_id VARCHAR(20) PRIMARY KEY,
    churn_status VARCHAR(20),
    contract_type VARCHAR(20),
    monthly_charges DECIMAL(10, 2),
    tier VARCHAR(10)
);

CREATE TABLE fact_subscriptions (
    customer_id VARCHAR(20),
    report_date DATE,
    status VARCHAR(20),
    mrr DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES dim_accounts(customer_id)
);

CREATE TABLE fact_support_tickets (
    ticket_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(20),
    ticket_date DATE,
    priority VARCHAR(20),
    category VARCHAR(50),
    resolution_time_hrs DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES dim_accounts(customer_id)
);

-- ------------------------------------------------------------------------------
-- PHASE 2: MASTER ANALYTICAL QUERY (THE GRAND FINALE)
-- Utilizes Window Functions (LAG, ROW_NUMBER) and Conditional Aggregation (CTEs)
-- ------------------------------------------------------------------------------
WITH mrr_dynamics AS (
    SELECT 
        customer_id,
        report_date,
        status,
        mrr AS current_mrr,
        LAG(mrr) OVER(PARTITION BY customer_id ORDER BY report_date) AS previous_mrr,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY report_date) AS active_month_number
    FROM fact_subscriptions
),
ticket_summary AS (
    SELECT 
        customer_id,
        COUNT(ticket_id) AS total_tickets,
        SUM(CASE WHEN priority = 'Escalated' THEN 1 ELSE 0 END) AS escalated_tickets
    FROM fact_support_tickets
    GROUP BY customer_id
)
-- Stitching the static dimension table with dynamic behavior models
SELECT 
    mrr_dynamics.customer_id,
    dim_accounts.tier,
    mrr_dynamics.active_month_number AS churn_month,
    mrr_dynamics.status,
    mrr_dynamics.current_mrr,
    COALESCE(ticket_summary.total_tickets, 0) AS total_tickets,
    COALESCE(ticket_summary.escalated_tickets, 0) AS escalated_tickets
FROM mrr_dynamics
JOIN dim_accounts ON mrr_dynamics.customer_id = dim_accounts.customer_id
LEFT JOIN ticket_summary ON mrr_dynamics.customer_id = ticket_summary.customer_id
WHERE mrr_dynamics.status = 'Churned'
ORDER BY ticket_summary.escalated_tickets DESC;