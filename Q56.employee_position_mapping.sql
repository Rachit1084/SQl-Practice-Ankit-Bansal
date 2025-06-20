/* Q 56
  
  Description:
    - Expanding job positions based on total sanctioned posts
    - Mapping employees to positions in row-wise order
    - Displaying vacant posts where applicable

  Objective:
    From a table of job positions (with total sanctioned posts),
    and a table of employees linked by position_id,
    generate a list of all sanctioned posts with either the employee
    name assigned or mark them as 'Vacant' if unfilled.

  Thought Process:
    - Explored two approaches:
      1. Recursive CTE to generate post rows
      2. Recursive number generator and join
    - Faced initial mental block, then solved using recursive logic
    - Used row_number() to map employees to available slots
    - Practicing SQL daily, building real-world scenarios
*/

-- ----------------------------------------
-- 1. TABLE CREATION AND SAMPLE DATA
-- ----------------------------------------

CREATE TABLE job_positions (
  id INT,
  title VARCHAR(100),
  groups VARCHAR(10),
  levels VARCHAR(10),
  payscale INT,
  totalpost INT
);

INSERT INTO job_positions VALUES
  (1, 'General Manager', 'A', 'L-15', 10000, 1),
  (2, 'Manager', 'B', 'L-14', 9000, 5),
  (3, 'Asst. Manager', 'C', 'L-13', 8000, 10);

CREATE TABLE job_employees (
  id INT,
  name VARCHAR(100),
  position_id INT
);

INSERT INTO job_employees VALUES
  (1, 'John Smith', 1),
  (2, 'Jane Doe', 2),
  (3, 'Michael Brown', 2),
  (4, 'Emily Johnson', 2),
  (5, 'William Lee', 3),
  (6, 'Jessica Clark', 3),
  (7, 'Christopher Harris', 3),
  (8, 'Olivia Wilson', 3),
  (9, 'Daniel Martinez', 3),
  (10, 'Sophia Miller', 3);

-- ----------------------------------------
-- 2. APPROACH 1: Using Recursive CTE
-- ----------------------------------------
-- This method expands rows recursively using row_number logic

WITH RECURSIVE emp AS (
  SELECT *,
         ROW_NUMBER() OVER(PARTITION BY position_id ORDER BY id) AS rw
  FROM job_employees
),
cte AS (
  SELECT id, title, groups, levels, payscale, totalpost,
         ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS rn
  FROM job_positions
  UNION ALL
  SELECT c.id, c.title, c.groups, c.levels, c.payscale, c.totalpost, c.rn + 1
  FROM cte c
  JOIN job_positions j ON c.id = j.id
  WHERE c.rn < c.totalpost
)
SELECT
  c.id,
  c.title,
  c.groups,
  c.levels,
  c.payscale,
  COALESCE(e.name, 'Vacant') AS employee_name
FROM cte c
LEFT JOIN emp e ON c.id = e.position_id AND c.rn = e.rw
ORDER BY c.id, c.rn;

-- ----------------------------------------
-- 3. APPROACH 2: Using Recursive Number Generator + Join
-- ----------------------------------------
-- This method uses a recursive number generator (1..max_totalpost) to join with job_positions

WITH RECURSIVE emp AS (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY position_id ORDER BY id) AS rw
  FROM job_employees
),
numbers AS (
  SELECT 1 AS rn
  UNION ALL
  SELECT rn + 1 FROM numbers
  WHERE rn < (SELECT MAX(totalpost) FROM job_positions)
),
cte AS (
  SELECT j.*, n.rn
  FROM job_positions j
  JOIN numbers n ON n.rn <= j.totalpost
)
SELECT
  c.id,
  c.title,
  c.groups,
  c.levels,
  c.payscale,
  COALESCE(e.name, 'Vacant') AS employee_name
FROM cte c
LEFT JOIN emp e ON c.id = e.position_id AND c.rn = e.rw
ORDER BY c.id, c.rn;

 