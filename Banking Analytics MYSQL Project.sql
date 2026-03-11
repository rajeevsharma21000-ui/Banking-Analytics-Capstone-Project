CREATE DATABASE Capstone;
USE Capstone;
select * from account;
select * from card;
select * from complaint;
select * from customer;
select * from date;
select * from loan;
select * from transaction;

# Data Validation Queries
SELECT COUNT(*) FROM customer;
SELECT COUNT(*) FROM account;
SELECT COUNT(*) FROM transaction;
SELECT COUNT(*) from card;
SELECT COUNT(*) from loan;
SELECT COUNT(*) from complaint;

-- Foreign key check

# Relationship Validation

# Account - Customer
SELECT *
FROM account a
LEFT JOIN customer c
ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

# Transaction - Account
SELECT *
FROM transaction t
LEFT JOIN account a
ON t.account_id = a.account_id
WHERE a.account_id IS NULL;



# KPI Queries

# Total Customer
SELECT COUNT(DISTINCT customer_id) AS total_customer
FROM customer;


# Active Customers Last(90 Days)
SELECT COUNT(DISTINCT a.customer_id) AS active_customer
FROM transaction t
JOIN account a ON t.account_id = a.account_id
WHERE t.transaction_date >= CURDATE() - INTERVAL 90 DAY;


# Total Deposit Balance
SELECT SUM(balance) AS total_deposit
FROM account;

# NPA Ratio
SELECT 
    COUNT(CASE WHEN loan_status = 'Defaulted' THEN 1 END) * 100.0 
    / COUNT(*) AS npa_ratio
FROM loan;

# Complete Resolution Rate
SELECT 
    COUNT(CASE WHEN resolution_status = 'Resolved' THEN 1 END) * 100.0 
    / COUNT(*) AS resolution_rate
FROM complaint;

# Branch Wise Deposit
SELECT branch, SUM(balance) AS deposit
FROM account
GROUP BY branch
ORDER BY deposit DESC;

# Loan Type Portfolio
SELECT loan_type, SUM(loan_amount) AS total_loan
FROM loan
GROUP BY loan_type;

# View For Connect to Power Bi

# Customer Summary View
CREATE VIEW customer_summary AS
SELECT 
    c.customer_id,
    c.city,
    COUNT(a.account_id) AS total_account,
    SUM(a.balance) AS total_balance
FROM customer c
LEFT JOIN account a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.city;

# Branch Performance View
CREATE VIEW vw_branch_performance AS
SELECT 
    branch,
    COUNT(account_id) AS total_account,
    SUM(balance) AS total_deposit
FROM account
GROUP BY branch;

# Monthly Transactions
DELIMITER $$

CREATE PROCEDURE monthly_transactions(IN yr INT, IN mn INT)
BEGIN
    SELECT COUNT(*) AS total_transactions,
           SUM(amount) AS total_amount
    FROM transactions
    WHERE YEAR(transaction_date) = yr
      AND MONTH(transaction_date) = mn;
END $$

DELIMITER ;

CALL monthly_transaction(2024, 6);


# 1) How would you identify active customers in the last 90 days?

SELECT COUNT(DISTINCT a.customer_id) AS active_customer
FROM transaction t
JOIN account a ON t.account_id = a.account_id
WHERE t.transaction_date >= CURDATE() - INTERVAL 90 DAY;

# 2) How do you calculate the NPA Ratio from the loans table?

SELECT 
    COUNT(CASE WHEN loan_status = 'Defaulted' THEN 1 END) * 100.0 
    / COUNT(*) AS npa_ratio
FROM loan;

# 3) Write a query to find branch-wise total deposits, sorted by performance.

SELECT 
    branch,
    SUM(balance) AS total_deposit
FROM account
GROUP BY branch
ORDER BY total_deposit DESC;

# 4) How would you find customers who have accounts but never made any transaction?

SELECT DISTINCT a.customer_id
FROM account a
LEFT JOIN transaction t 
    ON a.account_id = t.account_id
WHERE t.transaction_id IS NULL;

# 5) How do you calculate the complaint resolution rate?

SELECT 
    COUNT(CASE WHEN resolution_status = 'Resolved' THEN 1 END) * 100.0
    / COUNT(*) AS resolution_rate
FROM complaint;

# 6) Write a query to identify customers with multiple accounts.

SELECT 
    customer_id,
    COUNT(account_id) AS total_account
FROM account
GROUP BY customer_id
HAVING COUNT(account_id) > 1;

# 7) How would you calculate monthly transaction volume?

SELECT 
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS month,
    COUNT(transaction_id) AS total_transaction,
    SUM(amount) AS total_amount
FROM transaction
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY year, month;

# 8) How do you ensure data integrity between transactions and accounts?

SELECT *
FROM transaction t
LEFT JOIN account a
ON t.account_id = a.account_id
WHERE a.account_id IS NULL;

# 9) How would you detect dormant accounts (no transactions in last 180 days)?

SELECT 
    a.account_id
FROM account a
LEFT JOIN transaction t 
    ON a.account_id = t.account_id
GROUP BY a.account_id
HAVING MAX(t.transaction_date) < CURDATE() - INTERVAL 180 DAY
   OR MAX(t.transaction_date) IS NULL;

# 10) How would you identify loan customers who also have unresolved complaints?

SELECT DISTINCT l.customer_id
FROM loan l
JOIN complaint c ON l.customer_id = c.customer_id
WHERE l.loan_status = 'Active'
  AND c.resolution_status = 'Pending';

# 11) How would you calculate branch-wise NPA ratio?

SELECT 
    a.branch,
    COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) * 100.0 
    / COUNT(l.loan_id) AS branch_npa_ratio
FROM loan l
JOIN account a ON l.customer_id = a.customer_id
GROUP BY a.branch;

# 12) How would you find customers who own both credit cards and active loans?

SELECT DISTINCT c.customer_id
FROM customer c
JOIN card cd ON c.customer_id = cd.customer_id
JOIN loan l ON c.customer_id = l.customer_id
WHERE cd.card_type = 'Credit'
  AND l.loan_status = 'Active';

# 13) How would you build a daily transaction summary table for reporting?

CREATE TABLE daily_transaction_summary AS
SELECT 
    transaction_date,
    COUNT(transaction_id) AS total_txns,
    SUM(amount) AS total_amount
FROM transaction
GROUP BY transaction_date;

# 14) Which branch has the highest number of active customers?

SELECT 
    a.branch,
    COUNT(DISTINCT a.customer_id) AS active_customer
FROM transaction t
JOIN account a ON t.account_id = a.account_id
WHERE t.transaction_date >= CURDATE() - INTERVAL 90 DAY
GROUP BY a.branch
ORDER BY active_customer DESC
LIMIT 1;

# 15) Which service type has the lowest resolution rate?

SELECT 
    service_type,
    COUNT(CASE WHEN resolution_status = 'Resolved' THEN 1 END) * 100.0 
    / COUNT(*) AS resolution_rate
FROM complaint
GROUP BY service_type
ORDER BY resolution_rate ASC;

