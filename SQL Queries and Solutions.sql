-- 1. You're a Compensation analyst employed by a multinational corporation. Your Assignment is to Pinpoint Countries who give work fully remotely, for the title 'managers’ Paying salaries Exceeding $90,000 USD

SELECT DISTINCT
    (company_location)
FROM
    salaries
WHERE
    job_title LIKE '%Manager%'
        AND salary_in_usd > 90000
        AND remote_ratio = 100

-- 2.As a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms. you're tasked WITH Identifying top 5 Country Having greatest count of large (company size) number of companies.

SELECT 
    company_location, COUNT(*) AS 'cnt'
FROM
    (SELECT 
        *
    FROM
        salaries
    WHERE
        experience_level = 'EN'
            AND company_size = 'L') t
GROUP BY company_location
ORDER BY cnt DESC
LIMIT 5

-- 3. Picture yourself as a data scientist Working for a workforce management platform. Your objective is to calculate the percentage of employees. Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, Shedding light on the attractiveness of high-paying remote positions in today's job market.

set @total = (Select count(*) from salaries where salary_in_usd > 100000);
set @count = (Select count(*) from salaries where remote_ratio = 100 and salary_in_usd > 100000);
set @percentage = round(((Select @count)/(Select @total)*100),2);
SELECT @percentage AS 'Percentage'

-- 4. Imagine you're a data analyst Working for a global recruitment agency. Your Task is to identify the Locations where average salaries exceed the average salary for that job title in market for, helping your agency guide candidates towards lucrative opportunities.

SELECT DISTINCT
    (company_location)
FROM
    (SELECT 
        s.job_title, company_location, Average, Avg_per_country
    FROM
        (SELECT 
        job_title, AVG(salary_in_usd) AS 'Average'
    FROM
        salaries
    GROUP BY job_title) s
    INNER JOIN (SELECT 
        company_location,
            job_title,
            AVG(salary_in_usd) AS 'Avg_per_country'
    FROM
        salaries
    GROUP BY job_title , company_location) t ON s.job_title = t.job_title
    WHERE
        Avg_per_country > Average) u

-- 5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. Your job is to Find out for each job title which. Country pays the maximum average salary. This helps you to place your candidates in those countries.

Select job_title, company_location from (
Select *,dense_rank() over (partition by job_title order by Average desc) as 'rank' from 
(Select job_title, company_location, avg(salary_in_usd) as 'Average' from salaries group by job_title, company_location) t
) u where u.rank = 1

-- 6. As a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends across different company Locations. Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased over the Past few years (Countries WHERE data is available for 3 years Only(present year and past two years) providing Insights into Locations experiencing Sustained salary growth.

with rise as (
Select * from salaries where company_location in (
Select company_location from (
Select company_location, avg(salary_in_usd) as 'Average', count(distinct(work_year)) as 'cnt' from salaries where work_year >= year(current_date())-2 group by company_location having cnt = 3) t)
)

Select distinct(company_location) from (Select company_location,
MAX(CASE WHEN work_year = 2022 THEN Average END) as Avg_Salary_2022,
MAX(CASE WHEN work_year = 2023 THEN Average END) as Avg_Salary_2023,
MAX(CASE WHEN work_year = 2024 THEN Average END) as Avg_Salary_2024 from 
(Select company_location, work_year, avg(salary_in_usd) as 'Average' from rise group by company_location, work_year) g
group by company_location having Avg_Salary_2024 > Avg_Salary_2023 and Avg_Salary_2023 > Avg_Salary_2022) final

-- 7. Picture yourself as a workforce strategist employed by a global HR tech startup. Your Mission is to Determine the percentage of fully remote work for each experience level IN 2021 and compare it WITH the corresponding figures for 2024, Highlighting any significant Increases or decreases IN remote work Adoption over the years.

with remote_2021 as 
(
    Select a.experience_level, (b.Count/a.Total) as 'Percentage_2021'
    from
    (Select experience_level, count(*) as 'Total' from salaries where work_year = 2021 group by experience_level) a
    inner join 
    (Select experience_level, count(*) as 'Count' from salaries where work_year = 2021 and remote_ratio = 100 group by experience_level) b
    on a.experience_level = b.experience_level
),
remote_2024 as 
(
    Select s.experience_level, (t.Count/s.Total) as 'Percentage_2024'
    from
    (Select experience_level, count(*) as 'Total' from salaries where work_year = 2024 group by experience_level) s
    inner join 
    (Select experience_level, count(*) as 'Count' from salaries where work_year = 2024 and remote_ratio = 100 group by experience_level) t
    on s.experience_level = t.experience_level
)

Select u.experience_level, (u.Percentage_2021)*100 as 'Remote_2021' , (v.Percentage_2024)*100 as 'Remote_2024'
from remote_2021 u
inner join remote_2024 v on u.experience_level = v.experience_level

-- 8. As a Compensation specialist at a Fortune 500 company, you're tasked with analyzing salary trends over time. Your objective is to calculate the average salary increase percentage for each experience level and job title between the years 2023 and 2024, helping the company stay competitive IN the talent market.

with t as (
Select work_year, experience_level, job_title, avg(salary_in_usd) as 'Average' from salaries where work_year in (2023,2024) group by experience_level, job_title, work_year
)

Select *, round((((Salary_2024-Salary_2023)/Salary_2023)*100),2) as 'Changes' from 
(select experience_level, job_title,
MAX(CASE WHEN work_year = 2023 THEN Average END) as Salary_2023,
MAX(CASE WHEN work_year = 2024 THEN Average END) as Salary_2024
from t group by experience_level, job_title ) u where round((((Salary_2024-Salary_2023)/Salary_2023)*100),2) is not NULL

-- 9. You're a database administrator tasked with role-based access control for a company's employee database. Your goal is to implement a security measure where employees in different experience level (e.g. Entry Level, Senior level etc.) can only access details relevant to their respective experience level, ensuring data confidentiality and minimizing the risk of unauthorized access.

CREATE USER 'Entry_level'@'%' identified by 'EN'
CREATE VIEW entry_level as (Select * from salaries where experience_level = 'EN') 
GRANT Select on jobs.entry_level to 'Entry_level'@'%'
# SHOW PRIVILEGES

-- 10. You are working with a consultancy firm, your client comes to you with certain data and preferences such as (their year of experience , their employment type, company location and company size )  and want to make an transaction into different domain in data industry (like  a person is working as a data analyst and want to move to some other domain such as data science or data engineering etc.) your work is to  guide them to which domain they should switch to base on  the input they provided, so that they can now update their knowledge as  per the suggestion. The Suggestion should be based on average salary.

DELIMITER //

CREATE PROCEDURE GetAverageSalary(
    IN exp_lev VARCHAR(2), 
    IN emp_type VARCHAR(3), 
    IN comp_loc VARCHAR(2), 
    IN comp_size VARCHAR(2)
)
BEGIN
    SELECT job_title, experience_level, company_location, company_size, employment_type, 
           ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE experience_level = exp_lev 
      AND company_location = comp_loc 
      AND company_size = comp_size 
      AND employment_type = emp_type 
    GROUP BY job_title, experience_level, company_location, company_size, employment_type 
    ORDER BY avg_salary DESC;
END//

DELIMITER ;

CALL GetAverageSalary('EN', 'FT', 'US', 'M');

-- 11. As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data. Your Task is to know how many people were employed IN different types of companies AS per their size IN 2021.

SELECT 
    company_size, COUNT(company_size) AS 'Count of Employees'
FROM
    salaries
WHERE
    work_year = 2021
GROUP BY company_size

-- 12. Imagine you are a talent Acquisition specialist Working for an International recruitment agency. Your Task is to identify the top 3 job titles that command the highest average salary Among part-time Positions IN the year 2023. 

SELECT 
    job_title, AVG(salary_in_usd) AS 'Average'
FROM
    salaries
WHERE
    work_year = 2023
        AND employment_type = 'PT'
GROUP BY job_title
ORDER BY Average DESC
LIMIT 3

-- 13. As a database analyst you have been assigned the task to Select Countries where average mid-level salary is higher than overall mid-level salary for the year 2023.

SET @average = (Select avg(salary_in_usd) AS 'average' from salaries where experience_level='MI');
SELECT 
    company_location, AVG(salary_in_usd)
FROM
    salaries
WHERE
    experience_level = 'MI'
        AND salary_in_usd > @average
GROUP BY company_location;

-- 14. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to assess the annual salary growth rate for various job titles. By Calculating the percentage Increase in salary from previous year to this year, you aim to provide valuable Insights Into salary trends within different job roles.

SELECT 
    a.job_title,
    ROUND((((Salary_2024 - Salary_2023) / Salary_2023) * 100),
            2) AS '%Change'
FROM
    (SELECT 
        job_title, salary_in_usd AS 'Salary_2023'
    FROM
        salaries
    WHERE
        work_year = 2023
    GROUP BY job_title) a
        INNER JOIN
    (SELECT 
        job_title, salary_in_usd AS 'Salary_2024'
    FROM
        salaries
    WHERE
        work_year = 2024
    GROUP BY job_title) b ON a.job_title = b.job_title

-- 15. As a database analyst you have been assigned the task to Identify the company locations with the highest and lowest average salary for senior-level (SE) employees in 2023.

SELECT 
    company_location AS 'Max Location',
    AVG(salary_in_usd) AS 'Average'
FROM
    salaries
WHERE
    work_year = 2023
        AND experience_level = 'SE'
GROUP BY company_location
ORDER BY Average DESC
LIMIT 1;
SELECT 
    company_location AS 'Min Location',
    AVG(salary_in_usd) AS 'Average'
FROM
    salaries
WHERE
    work_year = 2023
        AND experience_level = 'SE'
GROUP BY company_location
ORDER BY Average ASC
LIMIT 1

-- 16. You've been hired by a global HR Consultancy to identify Countries experiencing significant salary growth for entry-level roles. Your task is to list the top three Countries with the highest salary growth rate FROM 2020 to 2023, helping multinational Corporations identify Emerging talent markets.

with new_table as (
Select company_location, work_year, avg(salary_in_usd) as 'Average' from salaries where experience_level = 'EN' group by company_location, work_year
) 

Select a.company_location, round((((Salary_2023 - Salary_2020)/Salary_2020)*100),2) as 'Growth' from 
(Select company_location, Average as 'Salary_2020' from new_table where work_year = 2020) a 
inner join 
(Select company_location, Average as 'Salary_2023' from new_table where work_year = 2023) b
on a.company_location = b.company_location order by Growth desc limit 3

-- 17. Picture yourself as a data architect responsible for database management. Companies in US and AU(Australia) decided to create a hybrid model for employees they decided that employees earning salaries exceeding $90000 USD, will be given work from home. You now need to update the remote work ratio for eligible employees, ensuring efficient remote work management while implementing appropriate error handling mechanisms for invalid input parameters.

CREATE TABLE camp AS SELECT * FROM
    salaries;
UPDATE camp 
SET 
    remote_ratio = 100
WHERE
    (company_location = 'AU'
        OR company_location = 'US')
        AND salary_in_usd > 90000;

-- 18. You have been hired by a market research agency where you been assigned the task to show the percentage of different employment type (full time, part time) in Different job roles, in the format where each row will be job title, each column will be type of employment type and cell value for that row and column will show the % value.

SELECT 
    job_title,
    ROUND((SUM(CASE
                WHEN employment_type = 'FT' THEN 1
                ELSE 0
            END) / COUNT(*)) * 100,
            2) AS FT_Percentage,
    ROUND((SUM(CASE
                WHEN employment_type = 'PT' THEN 1
                ELSE 0
            END) / COUNT(*)) * 100,
            2) AS PT_Percentage,
    ROUND((SUM(CASE
                WHEN employment_type = 'CT' THEN 1
                ELSE 0
            END) / COUNT(*)) * 100,
            2) AS CT_Percentage,
    ROUND((SUM(CASE
                WHEN employment_type = 'FL' THEN 1
                ELSE 0
            END) / COUNT(*)) * 100,
            2) AS FL_Percentage
FROM
    salaries
GROUP BY job_title

-- 19. You are a researcher and you have been assigned the task to find the year with the highest average salary for each job title.

SELECT 
    job_title, work_year, MAX(Average)
FROM
    (SELECT 
        work_year, job_title, AVG(salary_in_usd) AS 'Average'
    FROM
        salaries
    GROUP BY job_title , work_year) t
GROUP BY job_title

-- 20. In the year 2024, due to increased demand in the data industry, there was an increase in salaries of data field employees.
-- Entry Level-35% of the salary.
-- Mid junior – 30% of the salary.
-- Immediate senior level- 22% of the salary.
-- Expert level- 20% of the salary.
-- Director – 15% of the salary.
-- You must update the salaries accordingly and update them back in the original database.

CREATE TABLE salaries_dup AS SELECT * FROM
    salaries;
UPDATE salaries_dup 
SET 
    salary_in_usd = CASE
        WHEN experience_level = 'EN' THEN salary_in_usd * 1.35
        WHEN experience_level = 'MI' THEN salary_in_usd * 1.30
        WHEN experience_level = 'SE' THEN salary_in_usd * 1.22
        WHEN experience_level = 'EX' THEN salary_in_usd * 1.20
        WHEN experience_level = 'DX' THEN salary_in_usd * 1.15
        ELSE salary_in_usd
    END
WHERE
    work_year = 2024

