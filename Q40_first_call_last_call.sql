-- Q40: From a phone log history, find if the caller made both the first and last call of the day to the same recipient.

-- 📌 Dataset
CREATE TABLE phonelog (
  Callerid INT,
  Recipientid INT,
  Datecalled TIMESTAMP
);

INSERT INTO phonelog VALUES
  (1,2,'2019-01-01 09:00:00'),
  (1,3,'2019-01-01 17:00:00'),
  (1,4,'2019-01-01 23:00:00'),
  (2,5,'2019-07-05 09:00:00'),
  (2,3,'2019-07-05 17:00:00'),
  (2,3,'2019-07-05 17:20:00'),
  (2,5,'2019-07-05 23:00:00'),
  (2,3,'2019-08-01 09:00:00'),
  (2,3,'2019-08-01 17:00:00'),
  (2,5,'2019-08-01 19:30:00'),
  (2,4,'2019-08-02 09:00:00'),
  (2,5,'2019-08-02 10:00:00'),
  (2,5,'2019-08-02 10:45:00'),
  (2,4,'2019-08-02 11:00:00');

-- ✅ Original Logic (based on joining first and last calls)
WITH calls AS (
  SELECT 
    callerid,
    DATE(datecalled) AS called_date,
    MIN(datecalled) AS first_call,
    MAX(datecalled) AS last_call
  FROM phonelog
  GROUP BY callerid, DATE(datecalled)
)
SELECT 
  c.*, 
  p1.recipientid
FROM calls c
JOIN phonelog p1 
  ON c.callerid = p1.callerid AND c.first_call = p1.datecalled
JOIN phonelog p2 
  ON c.callerid = p2.callerid AND c.last_call = p2.datecalled
WHERE p1.recipientid = p2.recipientid;

-- 🔁 My Alternate Logic (using LAG function)
WITH tem AS (
  SELECT *, 
         LAG(recipientid) OVER(PARTITION BY p.callerid, x.dt ORDER BY p.datecalled) AS prev
  FROM phonelog p 
  JOIN (
    SELECT 
      callerid AS cd, 
      DATE(datecalled) AS dt, 
      MIN(datecalled), 
      MAX(datecalled)
    FROM phonelog 
    GROUP BY callerid, DATE(datecalled)
  ) x 
  ON p.callerid = x.cd AND (p.datecalled = x.min OR p.datecalled = x.max)
)
SELECT 
  callerid, 
  dt AS called_date, 
  recipientid 
FROM tem
WHERE prev = recipientid;
