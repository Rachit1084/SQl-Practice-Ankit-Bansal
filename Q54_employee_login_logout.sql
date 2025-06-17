/* Q 54
Employee Check-in Analysis - Three Approaches
Purpose: Demonstrate different SQL techniques to analyze employee login/logout patterns

Dataset Overview:
- employee_checkin_details: Tracks employee login/logout timestamps
- employee_details: Contains employee phone numbers with default flags

Key Skills Demonstrated:
- Conditional aggregation
- JOIN strategies (INNER, LEFT, FULL)
- Subquery optimization
- NULL handling
- Query performance considerations
*/

-- =============================================
-- TABLE CREATION & SAMPLE DATA
-- =============================================

CREATE TABLE employee_checkin_details (
    employeeid INTEGER,
    entry_details VARCHAR(10),
    timestamp_details TIMESTAMP
);

INSERT INTO employee_checkin_details VALUES
(1000, 'login', '2023-06-16 01:00:15.34'),
(1000, 'login', '2023-06-16 02:00:15.34'),
(1000, 'login', '2023-06-16 03:00:15.34'),
(1000, 'logout', '2023-06-16 12:00:15.34'),
(1001, 'login', '2023-06-16 01:00:15.34'),
(1001, 'login', '2023-06-16 02:00:15.34'),
(1001, 'login', '2023-06-16 03:00:15.34'),
(1001, 'logout', '2023-06-16 12:00:15.34');

CREATE TABLE employee_details (
    employeeid INTEGER,
    phone_number VARCHAR(10),
    isdefault BOOLEAN
);

INSERT INTO employee_details VALUES
(1001, '9999', false),
(1001, '1111', false),
(1001, '2222', true),
(1003, '3333', false);

-- =============================================
-- APPROACH 1: Comprehensive Analysis with FULL JOIN (Updated)
-- Best for: Complete employee coverage with default phone numbers
-- =============================================

SELECT 
    CASE WHEN x.employeeid IS NULL THEN ed.employeeid ELSE x.employeeid END AS e_id,
    x.total_entry,
    x.total_login,
    x.total_logout,
    x.latest_login,
    x.latest_logout,
    ed.phone_number,
    ed.isdefault 
FROM (
    SELECT  
        employeeid, 
        COUNT(*) AS total_entry,
        SUM(CASE WHEN entry_details = 'login' THEN 1 ELSE 0 END) AS total_login,
        SUM(CASE WHEN entry_details = 'logout' THEN 1 ELSE 0 END) AS total_logout,
        MAX(CASE WHEN entry_details = 'login' THEN timestamp_details END) AS latest_login,
        MAX(CASE WHEN entry_details = 'logout' THEN timestamp_details END) AS latest_logout
    FROM employee_checkin_details 
    GROUP BY employeeid
) x
FULL JOIN employee_details ed ON ed.employeeid = x.employeeid
WHERE ed.isdefault = 'true' OR ed.isdefault IS NULL OR x.employeeid IS NULL
ORDER BY e_id;

/*
Advantages:
- Guarantees all employees appear in results (even those without check-in records)
- Explicit NULL handling with CASE statement
- Filters for default phone numbers or NULL cases
- Preserves all original columns from both tables
- Clear one-row-per-employee output
*/

-- =============================================
-- APPROACH 2: CTE-Based Solution
-- Best for: Readability and modular analysis
-- =============================================

WITH logins AS (
    SELECT 
        employeeid, 
        COUNT(*) AS total_login,
        MAX(timestamp_details) AS latest_login
    FROM employee_checkin_details
    WHERE entry_details='login'
    GROUP BY employeeid
),
logouts AS (
    SELECT 
        employeeid, 
        COUNT(*) AS total_logout,
        MAX(timestamp_details) AS latest_logout
    FROM employee_checkin_details
    WHERE entry_details='logout'
    GROUP BY employeeid
)
SELECT 
    a.employeeid,
    c.phone_number AS default_phone,
    a.total_login,
    b.total_logout,
    a.total_login + b.total_logout AS total_entry,
    a.latest_login,
    b.latest_logout
FROM logins a
INNER JOIN logouts b ON a.employeeid = b.employeeid
LEFT JOIN employee_details c ON a.employeeid = c.employeeid AND c.isdefault = true;

/*
Advantages:
- Excellent readability with separated CTEs
- Clear separation of login/logout logic
- Easy to modify individual components
- Good for complex analytical queries
*/

-- =============================================
-- APPROACH 3: Concise Conditional Aggregation
-- Best for: Simple reporting with all phone numbers
-- =============================================

SELECT 
    a.employeeid, 
    c.phone_number,
    COUNT(*) AS total_entries,
    COUNT(CASE WHEN entry_details='login' THEN 1 END) AS total_logins,
    COUNT(CASE WHEN entry_details='logout' THEN 1 END) AS total_logouts,
    MAX(CASE WHEN entry_details='login' THEN timestamp_details END) AS latest_login,
    MAX(CASE WHEN entry_details='logout' THEN timestamp_details END) AS latest_logout
FROM employee_checkin_details a
LEFT JOIN employee_details c ON a.employeeid = c.employeeid
GROUP BY a.employeeid, c.phone_number
ORDER BY a.employeeid, c.isdefault DESC;

/*
Advantages:
- Most concise solution
- Shows all phone numbers
- Single-pass aggregation
- Good for quick ad-hoc analysis
*/

-- =============================================
-- PERFORMANCE NOTES:
-- 1. Approach 1 (Updated): Best for complete reporting, handles edge cases
-- 2. Approach 2: Best for complex analysis and readability
-- 3. Approach 3: Best for simple reports and performance
-- =============================================

-- =============================================
-- KEY IMPROVEMENTS IN UPDATED APPROACH 1:
-- 1. Fixed boolean comparison (isdefault = 'true')
-- 2. Added ed. prefix to isdefault in WHERE clause
-- 3. Preserved all original column selections
-- 4. Maintained consistent column naming
-- 5. Improved NULL handling logic
-- =============================================