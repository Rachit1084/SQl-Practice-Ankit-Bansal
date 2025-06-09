/*
FILE: 041_hiring_candidates_with_budget.sql
DESCRIPTION: SQL solution for hiring candidates with budget constraint
DIFFICULTY: Medium
CATEGORY: Window Functions/Problem Solving

PROBLEM STATEMENT:
We need to hire candidates with a $70,000 budget following these rules:
1. Must hire the maximum number of seniors first (within budget)
2. Then use remaining budget to hire maximum number of juniors
3. Within each experience level, hire candidates with lower salaries first

APPROACH:
The solution uses window functions to calculate running totals of salaries:
1. First solution separates seniors and juniors explicitly
2. Second solution handles both in a single pass with careful ordering

VALIDATION:
- Verified with multiple test cases including edge cases
- ChatGPT initially questioned logic but confirmed correctness after testing
- Handles cases where no seniors can be hired within budget
*/

-- =============================================
-- SAMPLE DATA SETUP
-- =============================================
CREATE TABLE candidates (
    emp_id INT,
    experience VARCHAR(20),
    salary INT
);

-- Primary test case
INSERT INTO candidates VALUES
(1, 'Junior', 10000),
(2, 'Junior', 15000),
(3, 'Junior', 40000),
(4, 'Senior', 16000),
(5, 'Senior', 20000),
(6, 'Senior', 50000);

-- Additional edge cases (commented out by default)
/*
INSERT INTO candidates VALUES
(7, 'Junior', 8000),       -- Additional junior with low salary
(8, 'Senior', 25000),      -- Additional senior
(9, 'Junior', 12000),      -- Another junior
(10, 'Senior', 18000),     -- Another senior
(11, 'Senior', 80000),     -- Senior with salary exceeding total budget
(12, 'Junior', 70000);     -- Junior with salary equaling total budget
*/

-- =============================================
-- SOLUTION 1: EXPLICIT SENIOR/JUNIOR SEPARATION
-- =============================================
/*
ADVANTAGES:
- More intuitive logic flow
- Easier to debug intermediate steps
- Explicit handling of senior budget calculation
*/
WITH total_sal AS (
    SELECT *, 
           SUM(salary) OVER(
               PARTITION BY experience 
               ORDER BY salary ASC 
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS running_sal
    FROM candidates
), 
seniors AS (
    SELECT * FROM total_sal 
    WHERE experience = 'Senior' AND running_sal <= 70000
)
SELECT emp_id, experience, salary 
FROM total_sal 
WHERE experience = 'Junior' 
  AND running_sal <= 70000 - (SELECT COALESCE(SUM(salary), 0) FROM seniors)
UNION ALL
SELECT emp_id, experience, salary FROM seniors
ORDER BY experience DESC, salary;  -- Seniors first, then by salary ascending

-- =============================================
-- SOLUTION 2: SINGLE-PASS WITH CUMULATIVE TOTALS
-- =============================================
/*
ADVANTAGES:
- More concise single query
- Efficient single pass through data
- Handles both experience levels in one logical flow
*/
WITH experience_level_totals AS (
    SELECT *,
           SUM(salary) OVER(
               PARTITION BY experience 
               ORDER BY salary
           ) AS experience_total 
    FROM candidates 
    ORDER BY experience DESC, salary  -- Seniors first, then by salary ascending
),
overall_totals AS (
    SELECT *,
           SUM(salary) OVER(
               ORDER BY experience DESC, salary
           ) AS overall_total 
    FROM experience_level_totals 
    WHERE experience_total <= 70000
)
SELECT emp_id, experience, salary
FROM overall_totals
WHERE overall_total <= 70000
ORDER BY experience DESC, salary;

-- =============================================
-- TEST INSTRUCTIONS
-- =============================================
/*
TO TEST DIFFERENT SCENARIOS:
1. Uncomment the additional edge cases
2. Run each solution separately
3. Verify results match expectations:
   - Seniors should be hired first (lowest salaries first)
   - Then juniors with remaining budget
   - Total should never exceed $70,000
*/