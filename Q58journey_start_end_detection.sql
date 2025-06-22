--Q58.
-- Purpose: To determine travel path insights from trip records.
 -- Description:
--   This script solves 3 key problems for each customer:
--     1. Identify the true start and end location of a journey
--     2. Explore two SQL approaches to do the same:
--          - Query 1: LEFT JOIN based approach
--          - Query 2: UNION ALL + COUNT OVER approach
--     3. Query 3 additionally computes total number of cities visited
--        by each customer using distinct location logic
 
-- Step 1: Create table
CREATE TABLE travel_data (
    customer VARCHAR(10),
    start_loc VARCHAR(50),
    end_loc VARCHAR(50)
);

-- Step 2: Insert sample data
INSERT INTO travel_data (customer, start_loc, end_loc) VALUES
    ('c1', 'New York', 'Lima'),
    ('c1', 'London', 'New York'),
    ('c1', 'Lima', 'Sao Paulo'),
    ('c1', 'Sao Paulo', 'New Delhi'),
    ('c2', 'Mumbai', 'Hyderabad'),
    ('c2', 'Surat', 'Pune'),
    ('c2', 'Hyderabad', 'Surat'),
    ('c3', 'Kochi', 'Kurnool'),
    ('c3', 'Lucknow', 'Agra'),
    ('c3', 'Agra', 'Jaipur'),
    ('c3', 'Jaipur', 'Kochi');

-- -------------------------------------------------------------
-- Query 1: Using LEFT JOINs to find unmatched start/end points
-- Author: Custom solution (my approach)
-- -------------------------------------------------------------
WITH cte AS (
    SELECT t1.*, 
           t2.customer AS start_l, 
           t3.customer AS end_l
    FROM travel_data t1
    LEFT JOIN travel_data t2 
        ON t1.customer = t2.customer AND t1.start_loc = t2.end_loc
    LEFT JOIN travel_data t3 
        ON t1.customer = t3.customer AND t1.end_loc = t3.start_loc
)
SELECT customer,
       MAX(CASE WHEN start_l IS NULL THEN start_loc END) AS start_location,
       MAX(CASE WHEN end_l IS NULL THEN end_loc END) AS end_location
FROM cte
WHERE start_l IS NULL OR end_l IS NULL
GROUP BY customer;

-- -------------------------------------------------------------
-- Query 2: Using UNION ALL + COUNT OVER to detect unique points
-- Author: As in reference video
-- -------------------------------------------------------------
WITH cte AS (
    SELECT customer, start_loc AS loc, 'start_loc' AS column_name FROM travel_data
    UNION ALL
    SELECT customer, end_loc AS loc, 'end_loc' AS column_name FROM travel_data
),
cte_2 AS (
    SELECT *,
           COUNT(*) OVER (PARTITION BY customer, loc) AS cnt
    FROM cte
)
SELECT customer,
       MAX(CASE WHEN column_name = 'start_loc' THEN loc END) AS start_location,
       MAX(CASE WHEN column_name = 'end_loc' THEN loc END) AS end_location
FROM cte_2
WHERE cnt = 1
GROUP BY customer;

-- -------------------------------------------------------------
-- Query 3: Start + End + Total Cities Visited (Combined Query)
-- Additionally found total city count 
-- -------------------------------------------------------------
WITH all_legs AS (
    SELECT t1.*, 
           t2.customer AS start_l, 
           t3.customer AS end_l
    FROM travel_data t1
    LEFT JOIN travel_data t2 
        ON t1.customer = t2.customer AND t1.start_loc = t2.end_loc
    LEFT JOIN travel_data t3 
        ON t1.customer = t3.customer AND t1.end_loc = t3.start_loc
),
unique_cities AS (
    SELECT customer, start_loc AS loc FROM travel_data
    UNION
    SELECT customer, end_loc FROM travel_data
)
SELECT 
    a.customer,
    MAX(CASE WHEN start_l IS NULL THEN start_loc END) AS start_location,
    MAX(CASE WHEN end_l IS NULL THEN end_loc END) AS end_location,
    (SELECT COUNT(DISTINCT loc) 
     FROM unique_cities uc 
     WHERE uc.customer = a.customer) AS total_visited
FROM all_legs a
WHERE start_l IS NULL OR end_l IS NULL
GROUP BY a.customer;
