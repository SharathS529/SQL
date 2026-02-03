use bankloananalysis;
select * from finance_1;
truncate finance_1;
Alter table finance_2 modify column Last_credit_pull_d date;

Describe finance_1;
select * from finance_2;
truncate finance_2;
describe finance_2;

SHOW VARIABLES LIKE 'secure_file_priv';

#     C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\Bank

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Bank Loan Analysis/finance_1.csv' into table finance_1
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Bank Loan Analysis/finance_2.csv' into table finance_2
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

Select * from finance_1;
select * from finance_2;

#building relationship
ALTER TABLE Finance_2
ADD CONSTRAINT fk_finance_customer
FOREIGN KEY (id)
REFERENCES Finance_1(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

SHOW CREATE TABLE Finance_2;


# KPI 1 - YEAR WISE LOAN AMOUNT

SELECT 
    YEAR(Issue_Date) AS issue_year,
    CONCAT(ROUND(SUM(loan_amnt) / 1000000, 2), 'M') AS total_loan_amount
FROM
    finance_1
GROUP BY YEAR(Issue_Date)
ORDER BY YEAR(Issue_Date);

# KPI 2 - GRADE AND SUB-GRADE WISE REVOLVING BALANCE

SELECT 
    f1.grade,
    f1.sub_grade,
    CONCAT(ROUND(SUM(f2.revol_bal) / 1000000, 2),'M') AS total_revol_bal
FROM
    finance_1 f1
        JOIN
    finance_2 f2 ON f1.id = f2.id
GROUP BY f1.grade , f1.sub_grade
ORDER BY f1.grade , f1.sub_grade;  

# KPI 3 - TOTAL PAYMENT FOR VERIFIED STATUS VS NON-VERIFIED STATUS

SELECT 
    verification_status,
    CONCAT(ROUND(SUM(f2.total_pymnt) / 1000000, 2),'M') AS total_payment
FROM
    finance_1 f1
        JOIN
    finance_2 f2 ON f1.id = f2.id
WHERE
    verification_status != 'Source Verified'
GROUP BY verification_status
ORDER BY total_payment DESC;

#in percentage
SELECT 
    verification_status,
    CONCAT(
        ROUND((status_total / grand_total) * 100, 2),
        '%'
    ) AS payment_percentage
FROM (
    SELECT 
        verification_status,
        SUM(f2.total_pymnt) AS status_total,
        SUM(SUM(f2.total_pymnt)) OVER () AS grand_total
    FROM finance_1 f1
    JOIN finance_2 f2 
        ON f1.id = f2.id
    WHERE verification_status <> 'Source Verified'
    GROUP BY verification_status
) t;

#KPI 4 - STATE WISE AND MONTH WISE LOAN STATUS

SELECT 
    f1.addr_state AS state,
    f1.loan_status,
    MONTHNAME(Issue_Date) AS issue_month,
    COUNT(loan_status) AS loan_count
FROM
    finance_1 f1
GROUP BY state , f1.loan_status , issue_month
ORDER BY state , f1.loan_status , loan_count DESC;

#KPI 5 - HOME OWNERSHIP VS LAST PAYMENT DATE

SELECT 
    f1.home_ownership,
    COUNT(home_ownership) AS loans_count,
    DATE_FORMAT(f2.Last_payment_d, '%Y-%M') AS Last_payment_date
FROM
    finance_1 f1
        JOIN
    finance_2 f2 ON f1.id = f2.id
GROUP BY f1.home_ownership , f2.Last_payment_d
ORDER BY loans_count DESC;

