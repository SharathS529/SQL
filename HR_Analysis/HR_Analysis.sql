use hr_analytics;
select *from hr_1;
truncate hr_1;

truncate hr_2;

ALTER TABLE hr_1 RENAME COLUMN ï»¿Age TO Age;


SHOW VARIABLES LIKE 'secure_file_priv';

#     C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\Bank

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Hr_Analysis/hr_1.csv' into table hr_1
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/HR_Analysis/hr_2.csv' into table hr_2
FIELDS TERMINATED by ','
optionally  enclosed by '"'
lines terminated by '\r\n'
IGNORE 1 rows;

#KPI 1 - AVERAGE ATTRITION RATE FOR ALL DEPARTMENTS
 
 CREATE TABLE kpi_avg_attrition_by_dept 
SELECT
  Department,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition IN ('Yes','Y','1') THEN 1 ELSE 0 END) AS attrited_count,
  CONCAT(ROUND(100.0 * SUM(CASE WHEN Attrition IN ('Yes','Y','1') THEN 1 ELSE 0 END) / COUNT(*), 2),"%") AS attrition_pct
FROM hr_1
GROUP BY Department
ORDER BY attrition_pct DESC;
SELECT * FROM kpi_avg_attrition_by_dept;

#KPI 2 - AVERAGE HOURLY RATE OF MALE RESEARCH SCIENTIST

CREATE TABLE kpi_avg_hourly_male_research_scientist 
SELECT
  COUNT(*) AS sample_size,
  ROUND(AVG(HourlyRate), 2) AS avg_hourly_rate
FROM hr_1
WHERE Gender = 'Male'
  AND JobRole = 'Research Scientist';
  SELECT * FROM kpi_avg_hourly_male_research_scientist; 
  
  #KPI 3 - ATTRITION RATE VS MONTHLY INCOME

CREATE TABLE kpi_attrition_vs_monthlyincome 
SELECT 
    COUNT(*) AS employees,
    SUM(is_attrited) AS attrited,
    CONCAT(ROUND(100.0 * SUM(is_attrited) / NULLIF(COUNT(*), 0),
                    2),
            '%') AS attrition_pct,
    ROUND(AVG(hr_2.MonthlyIncome), 2) AS avg_income,
    income_bucket
FROM
    (SELECT 
        *,
            CASE
                WHEN hr_2.MonthlyIncome IS NULL THEN 'Unknown'
                WHEN hr_2.MonthlyIncome < 20000 THEN '<20k'
                WHEN hr_2.MonthlyIncome BETWEEN 20000 AND 40000 THEN '20k-40k'
                WHEN hr_2.MonthlyIncome BETWEEN 40000 AND 60000 THEN '40k-60k'
                WHEN hr_2.MonthlyIncome BETWEEN 60000 AND 80000 THEN '60k-80k'
                ELSE '>=80k'
            END AS income_bucket,
            CASE
                WHEN Attrition IN ('Yes' , 'Y', '1') THEN 1
                ELSE 0
            END AS is_attrited
    FROM
        hr_1
    INNER JOIN hr_2 ON hr_1.EmployeeNumber = hr_2.EmployeeID) hr_1
        INNER JOIN
    hr_2 ON hr_1.EmployeeNumber = hr_2.EmployeeID
GROUP BY income_bucket
ORDER BY CASE income_bucket
    WHEN '<20k' THEN 1
    WHEN '20k-40k' THEN 2
    WHEN '40k-60k' THEN 3
    WHEN '60k-80k' THEN 4
    WHEN '>=80k' THEN 5
    ELSE 99
END;
SELECT * FROM kpi_attrition_vs_monthlyincome;

#KPI 4 - AVERAGE WORKING YEARS FOR EACH DEPARTMENT
CREATE TABLE kpi_avg_years_by_dept 
SELECT
  Department,
  COUNT(*) AS employees,
  ROUND(AVG(TotalWorkingYears),2) AS avg_total_working_years,
  ROUND(AVG(YearsAtCompany),2) AS avg_years_at_company
FROM hr_1 INNER JOIN hr_2 ON hr_1.EmployeeNumber = hr_2.EmployeeID
GROUP BY Department
ORDER BY avg_total_working_years DESC;
SELECT * FROM kpi_avg_years_by_dept;

#KPI 5 - JOB ROLE VS WORK-LIFE BALANCE

CREATE TABLE kpi_jobrole_worklife_balance 
SELECT
  JobRole,
  COUNT(*) AS employees,
  ROUND(AVG(WorkLifeBalance),2) AS avg_worklife_balance
FROM hr_1 INNER JOIN hr_2 ON hr_1.EmployeeNumber = hr_2.EmployeeID
GROUP BY JobRole
ORDER BY avg_worklife_balance DESC;
SELECT * FROM kpi_jobrole_worklife_balance;

#KPI 6 - ATTRITION RATE VS YEARS SINCE LAST PROMOTION

CREATE TABLE kpi_attrition_vs_years_since_promotion 
SELECT
    CASE 
        WHEN YearsSinceLastPromotion BETWEEN 0 AND 1 THEN '0-1 Years'
        WHEN YearsSinceLastPromotion BETWEEN 2 AND 3 THEN '2-3 Years'
        WHEN YearsSinceLastPromotion BETWEEN 4 AND 5 THEN '4-5 Years'
        WHEN YearsSinceLastPromotion BETWEEN 6 AND 10 THEN '6-10 Years'
        ELSE '10+ Years'
    END AS YearsSinceLastPromotion_Band,
    
    COUNT(*) AS Employee_Count

FROM hr_1 h1
INNER JOIN hr_2 h2 
    ON h1.EmployeeNumber = h2.EmployeeID

GROUP BY 
    CASE 
        WHEN YearsSinceLastPromotion BETWEEN 0 AND 1 THEN '0-1 Years'
        WHEN YearsSinceLastPromotion BETWEEN 2 AND 3 THEN '2-3 Years'
        WHEN YearsSinceLastPromotion BETWEEN 4 AND 5 THEN '4-5 Years'
        WHEN YearsSinceLastPromotion BETWEEN 6 AND 10 THEN '6-10 Years'
        ELSE '10+ Years'
    END
ORDER BY MIN(YearsSinceLastPromotion);
SELECT * FROM kpi_attrition_vs_years_since_promotion;


create table HR AS 
Select 
   h1.*,
   h2.*
from hr_1 h1
LEFT join hr_2 h2
on h1.EmployeeNumber = h2.EmployeeID;

ALTER TABLE hr
ADD YearsBand VARCHAR(20);

UPDATE hr
SET YearsBand = 
    CASE 
        WHEN YearsSinceLastPromotion BETWEEN 0 AND 2 THEN '0-2 Years'
        WHEN YearsSinceLastPromotion BETWEEN 3 AND 5 THEN '3-5 Years'
        WHEN YearsSinceLastPromotion BETWEEN 6 AND 10 THEN '6-10 Years'
        ELSE '11+ Years'
    END;
SET SQL_SAFE_UPDATES=0;

ALTER TABLE hr
ADD IncomeBand VARCHAR(20);

UPDATE hr
SET IncomeBand =
    CASE 
        WHEN MonthlyIncome <= 20000 THEN 'Low Income'
        WHEN MonthlyIncome BETWEEN 20001 AND 50000 THEN 'Medium Income'
        ELSE 'High Income'
    END;
    
   ALTER TABLE hr
DROP COLUMN IncomeBand;

UPDATE hr
SET department = 'HR'
WHERE department = 'Human Resources';

select * from hr_1;
UPDATE hr
SET department = 'R&D'
WHERE department = 'Research & Development';
select * from hr_1;