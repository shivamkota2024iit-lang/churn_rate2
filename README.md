# Telco Customer Churn: End-to-End Data Engineering & Analytics Case Study

## 📌 Executive Summary
Standard churn analyses stop at a flat CSV file and a post-mortem model score[cite: 1]. This project replicates the data architecture of a real enterprise: a Kaggle-style telecom dataset was reverse-engineered into a normalized **MySQL Star Schema** with event-level operational data, then interrogated with an advanced SQL analytics engine to test a specific behavioral hypothesis[cite: 1].

## 🎯 Core Hypothesis
**Do premium ('Tier 2') customers exhibit a distinct behavioral anomaly—a high volume of 'Escalated' support tickets—between their 7th and 11th month of subscription, just before churning?**
* **Finding:** Yes. High-risk Tier 2 accounts experience a **4.7x surge in escalated tickets** (11 $\rightarrow$ 52) and a **-46% MRR contraction** ($24.4 $\rightarrow$ $13.1) during Months 7–11[cite: 6], providing Customer Success teams with a **5-month early-warning lead time**[cite: 2, 6].

---

## 🏗️ Solution Architecture & Tech Stack
* **Languages & Libraries:** Python (`pandas`, `numpy`)[cite: 1]
* **Database & Ingestion:** MySQL (Star Schema, `LOAD DATA INFILE` bulk ingestion, solving `secure-file-priv` Error 1290)[cite: 1]
* **Analytical Engine:** Advanced SQL (Common Table Expressions, Window Functions)[cite: 1, 2]
* **Visualization:** Power BI (Dual-axis combo chart with custom warning bands)[cite: 1, 2]

### Data Model (Star Schema)
* **`dim_accounts` (Dimension):** Static customer profiles, tenure, and tier segmentation[cite: 1].
* **`fact_subscriptions` (Fact):** Monthly Recurring Revenue (MRR) time-series log per account[cite: 1].
* **`fact_support_tickets` (Fact):** Event log of 12,500+ customer-service interactions, including priority levels[cite: 1].

---

## 🔍 The SQL Analytical Engine (Zero Fan-Out Master Query)
The project utilizes a modular CTE-driven query to flatten time-series events without row duplication:
1. **CTE 1 (`ROW_NUMBER()`):** Sequences each account's chronological active lifespan to isolate the Months 7–11 window[cite: 1, 2].
2. **CTE 2 (`LAG()`):** Tracks month-over-month MRR fluctuations to surface revenue contraction ahead of cancellation.
3. **CTE 3 (`SUM(CASE WHEN...)`):** The "Tally Mark" pattern compresses 12,500+ raw support ticket rows into a single scorecard row per customer[cite: 1, 2].
4. **Master Join (`LEFT JOIN` + `COALESCE()`):** Stitches dynamic CTEs back to `dim_accounts`, preserving every customer and defaulting missing events to zero.

---

## 🚀 Repository File Structure
```text
├── 01_python_etl_generator.py      # Python script for synthetic time-series expansion & normalization
├── 02_mysql_star_schema_load.sql   # DDL schema definition & bulk INFILE ingestion scripts
└── sql_project1.sql                # Master CTE analytical query powering the Power BI dashboard
