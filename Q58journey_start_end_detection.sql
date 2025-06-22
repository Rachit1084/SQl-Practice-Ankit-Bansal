--##58
-- Purpose: To determine the true starting and ending location
--          of each customer's journey based on travel records.
-- Description:
--   Query 1: Uses LEFT JOIN logic to find unmatched start/end.
--   Query 2: Uses UNION ALL + COUNT OVER to identify unique points.
-- -------------------------------------------------------------

-- Step 1: Create table
DROP TABLE IF EXISTS travel_data;
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
-- Query 1: My own alternative solution 
--         Using LEFT JOINs to find unmatched start/end points
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
-- Author: Original query from reference video
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
