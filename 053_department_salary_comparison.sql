/* Q53
PROBLEM: Dynamic Department Salary Comparison
We need to find departments with an average salary lower than the company's average salary,
where the company average EXCLUDES the department being compared.

KEY REQUIREMENTS:
1. Calculate department average salary
2. Calculate company average salary EXCLUDING the department being compared
3. Compare department average with this dynamic company average
4. Return only departments where department average < company average

APPROACHES:
1. Video Solution: Uses self-join on department CTE
2. Alternative Solution: Uses window functions for cleaner logic
*/

-- ======================
-- SAMPLE DATA SETUP
-- ======================
CREATE TABLE emp (
    emp_id int,
    emp_name varchar(20),
    department_id int,
    salary int,
    manager_id int,
    emp_age int
);

INSERT INTO emp VALUES 
(1, 'Ankit', 100, 10000, 4, 39),
(2, 'Mohit', 100, 15000, 5, 48),
(3, 'Vikas', 100, 10000, 4, 37),
(4, 'Rohit', 100, 5000, 2, 16),
(5, 'Mudit', 200, 12000, 6, 55),
(6, 'Agam', 200, 12000, 2, 14),
(7, 'Sanjay', 200, 9000, 2, 13),
(8, 'Ashish', 200, 5000, 2, 12),
(9, 'Mukesh', 300, 6000, 6, 51),
(10, 'Rakesh', 300, 7000, 6, 50);

-- ======================
-- SOLUTION 1: VIDEO APPROACH
-- ======================
/*
ADVANTAGES:
- More traditional approach using GROUP BY and self-join
- Easier to understand for those familiar with joins

DISADVANTAGES:
- Requires self-join which can be inefficient for large datasets
- More complex to read with nested subqueries
*/
WITH department_stats AS (
    SELECT 
        department_id, 
        AVG(salary) AS dept_avg, 
        SUM(salary) AS total_salary, 
        COUNT(*) AS total_emp 
    FROM emp
    GROUP BY department_id
)
SELECT 
    department_id, 
    ROUND(dept_avg, 2) AS department_average,
    ROUND(company_avg_dynamic, 2) AS company_average_excluding_dept
FROM (
    SELECT 
        d1.department_id, 
        d1.dept_avg, 
        SUM(d2.total_salary)/SUM(d2.total_emp) AS company_avg_dynamic
    FROM department_stats d1
    JOIN department_stats d2 ON d1.department_id != d2.department_id
    GROUP BY d1.department_id, d1.dept_avg
) AS comparison
WHERE dept_avg < company_avg_dynamic
ORDER BY department_id;

-- ======================
-- SOLUTION 2: WINDOW FUNCTION APPROACH
-- ======================
/*
ADVANTAGES:
- Single pass through data using window functions
- More efficient for large datasets
- Cleaner, more modern SQL approach

DISADVANTAGES:
- Requires understanding of window functions
- Slightly more complex calculations
*/
WITH emp_stats AS (
    SELECT *,
           AVG(salary) OVER(PARTITION BY department_id) AS dept_avg,
           COUNT(*) OVER(PARTITION BY department_id) AS dept_count,
           SUM(salary) OVER(PARTITION BY department_id) AS dept_total,
           SUM(salary) OVER() AS total_salary,
           COUNT(*) OVER() AS total_count
    FROM emp
),
distinct_departments AS (
    SELECT DISTINCT 
        department_id, 
        dept_avg, 
        dept_total, 
        dept_count, 
        total_salary, 
        total_count
    FROM emp_stats
),
company_comparison AS (
    SELECT
        department_id,
        ROUND(dept_avg, 2) AS department_average,
        ROUND((total_salary - dept_total) * 1.0 / (total_count - dept_count), 2) AS company_average_excluding_dept
    FROM distinct_departments
)
SELECT * 
FROM company_comparison
WHERE department_average < company_average_excluding_dept
ORDER BY department_id;

-- ======================
-- PERFORMANCE COMPARISON
-- ======================
/*
BENCHMARK NOTES:
- Window function approach is generally faster for large datasets
- Join approach may be better for small datasets with few departments
- Both produce identical results for this problem
*/

-- ======================
-- TEST CASES
-- ======================
/*
VERIFICATION:
1. Department 100: Avg = 10,000
   Company Avg (excl 100) = (12000+9000+5000+6000+7000)/5 = 8,200
   Should NOT appear in results (10,000 > 8,200)

2. Department 200: Avg = (12000+12000+9000+5000)/4 = 9,500
   Company Avg (excl 200) = (10000+15000+10000+5000+6000+7000)/6 = 8,500
   Should NOT appear (9,500 > 8,500)

3. Department 300: Avg = (6000+7000)/2 = 6,500
   Company Avg (excl 300) = (10000+15000+10000+5000+12000+12000+9000+5000)/8 = 9,750
   SHOULD appear in results (6,500 < 9,750)
*/