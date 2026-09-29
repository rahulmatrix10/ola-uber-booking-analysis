/*
PROJECT: Ola/Uber Ride Booking Analysis
AUTHOR: Rahul Ballidav
TOOLS: MySQL + Power BI

PURPOSE
Analyse ride bookings, booking outcomes, cancellations, locations, vehicle types,
recorded booking value, payments, ratings, turnaround-time fields, and repeat customers.

IMPORTANT
1. Run the setup/load section only when you want to rebuild the table from bookings.csv.
2. The script recreates the Bookings table and therefore replaces any existing table
   with the same name. Back up any work you need before running the full script.
3. Confirm the actual values in Booking_Status and Incomplete_Rides before interpreting
   queries that filter for 'Success' or 'Yes'.
4. Booking_Value is called "recorded booking value" in this project. Do not call it
   collected revenue or profit unless the dataset/business definition supports that.
5. V_TAT and C_TAT units/definitions must be verified before calling them minutes.
*/

-- =========================================================
-- SECTION 1: DATABASE SETUP AND DATA LOAD
-- =========================================================

CREATE DATABASE IF NOT EXISTS ola_uber_data;
USE ola_uber_data;

DROP TABLE IF EXISTS Bookings;

CREATE TABLE Bookings (
    `Date` DATE,
    `Time` TIME,
    Booking_ID VARCHAR(50),
    Booking_Status VARCHAR(50),
    Customer_ID VARCHAR(50),
    Vehicle_Type VARCHAR(50),
    Pickup_Location VARCHAR(100),
    Drop_Location VARCHAR(100),
    V_TAT INT,
    C_TAT INT,
    Canceled_Rides_by_Customer VARCHAR(100),
    Canceled_Rides_by_Driver VARCHAR(100),
    Incomplete_Rides VARCHAR(10),
    Incomplete_Rides_Reason VARCHAR(255),
    Booking_Value DECIMAL(10, 2),
    Payment_Method VARCHAR(50),
    Ride_Distance DECIMAL(10, 2),
    Driver_Ratings DECIMAL(3, 1),
    Customer_Rating DECIMAL(3, 1)
);

-- LOAD DATA uses the server-side MySQL Uploads folder.
-- Check the file path, file permissions, and line endings if loading fails.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/bookings.csv'
INTO TABLE Bookings
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @var_Date,
    @var_Time,
    Booking_ID,
    Booking_Status,
    Customer_ID,
    Vehicle_Type,
    Pickup_Location,
    Drop_Location,
    @var_V_TAT,
    @var_C_TAT,
    @var_Canceled_Cust,
    @var_Canceled_Driver,
    @var_Incomplete_Rides,
    @var_Incomplete_Reason,
    @var_Booking_Value,
    @var_Payment_Method,
    @var_Ride_Distance,
    @var_Driver_Ratings,
    @var_Customer_Rating
)
SET
    `Date` = STR_TO_DATE(NULLIF(NULLIF(@var_Date, ''), 'null'), '%d-%m-%Y'),
    `Time` = NULLIF(NULLIF(@var_Time, ''), 'null'),
    V_TAT = NULLIF(NULLIF(@var_V_TAT, ''), 'null'),
    C_TAT = NULLIF(NULLIF(@var_C_TAT, ''), 'null'),
    Canceled_Rides_by_Customer = NULLIF(NULLIF(@var_Canceled_Cust, ''), 'null'),
    Canceled_Rides_by_Driver = NULLIF(NULLIF(@var_Canceled_Driver, ''), 'null'),
    Incomplete_Rides = NULLIF(NULLIF(@var_Incomplete_Rides, ''), 'null'),
    Incomplete_Rides_Reason = NULLIF(NULLIF(@var_Incomplete_Reason, ''), 'null'),
    Booking_Value = NULLIF(NULLIF(@var_Booking_Value, ''), 'null'),
    Payment_Method = NULLIF(NULLIF(@var_Payment_Method, ''), 'null'),
    Ride_Distance = NULLIF(NULLIF(@var_Ride_Distance, ''), 'null'),
    Driver_Ratings = NULLIF(NULLIF(@var_Driver_Ratings, ''), 'null'),
    Customer_Rating = NULLIF(NULLIF(@var_Customer_Rating, ''), 'null');

-- =========================================================
-- SECTION 2: DATA VALIDATION
-- =========================================================

-- Q1. What booking statuses exist, and how many records are in each?
-- Business purpose: understand the available booking outcomes before filtering.
SELECT
    Booking_Status,
    COUNT(*) AS total_bookings
FROM Bookings
GROUP BY Booking_Status
ORDER BY total_bookings DESC;

-- Q2. How many rows/bookings are in the table?
-- Business purpose: establish the dataset size.
SELECT COUNT(*) AS total_rows
FROM Bookings;

-- Q3. Are there duplicate non-blank Booking_ID values?
-- Expected: no rows if every non-blank Booking_ID is unique.
SELECT
    Booking_ID,
    COUNT(*) AS occurrences
FROM Bookings
WHERE Booking_ID IS NOT NULL
  AND TRIM(Booking_ID) <> ''
GROUP BY Booking_ID
HAVING COUNT(*) > 1;

-- Q4. How many important fields are missing?
-- This aggregate query should return one summary row, not one row per booking.
SELECT
    SUM(Booking_ID IS NULL OR TRIM(Booking_ID) = '') AS missing_booking_ids,
    SUM(Customer_ID IS NULL OR TRIM(Customer_ID) = '') AS missing_customer_ids,
    SUM(`Date` IS NULL) AS missing_dates,
    SUM(Booking_Status IS NULL OR TRIM(Booking_Status) = '') AS missing_statuses,
    SUM(Vehicle_Type IS NULL OR TRIM(Vehicle_Type) = '') AS missing_vehicle_types,
    SUM(Booking_Value IS NULL) AS missing_booking_values,
    SUM(Ride_Distance IS NULL) AS missing_ride_distances,
    SUM(Customer_Rating IS NULL) AS missing_customer_ratings,
    SUM(Driver_Ratings IS NULL) AS missing_driver_ratings
FROM Bookings;

-- Q5. What period does the dataset cover, and how many customers/vehicle types exist?
SELECT
    MIN(`Date`) AS first_booking_date,
    MAX(`Date`) AS last_booking_date,
    COUNT(DISTINCT `Date`) AS distinct_booking_dates,
    COUNT(DISTINCT Customer_ID) AS unique_customer_ids,
    COUNT(DISTINCT Vehicle_Type) AS distinct_vehicle_types
FROM Bookings;

-- Q6. Are there unexpected values in the incomplete-ride flag?
SELECT
    Incomplete_Rides,
    COUNT(*) AS total_bookings
FROM Bookings
GROUP BY Incomplete_Rides
ORDER BY total_bookings DESC;

-- Q7. What payment methods are recorded?
SELECT
    Payment_Method,
    COUNT(*) AS total_bookings
FROM Bookings
GROUP BY Payment_Method
ORDER BY total_bookings DESC;

-- =========================================================
-- SECTION 3: BOOKING PERFORMANCE AND TIME TRENDS
-- =========================================================

-- Q8. What percentage of all bookings belongs to each status?
SELECT
    Booking_Status,
    COUNT(*) AS total_bookings,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM Bookings), 0), 2)
        AS percentage_of_all_bookings
FROM Bookings
GROUP BY Booking_Status
ORDER BY total_bookings DESC;

-- Q9. What is the successful booking rate?
-- Confirm from Q1 that 'Success' is the exact status value used in the data.
SELECT
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings,
    ROUND(SUM(Booking_Status = 'Success') * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS success_rate_pct
FROM Bookings;

-- Q10. How do total and successful bookings change month by month?
SELECT
    DATE_FORMAT(`Date`, '%Y-%m') AS booking_month,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings
FROM Bookings
WHERE `Date` IS NOT NULL
GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY booking_month;

-- Q11. Which days of the week have the most bookings?
SELECT
    DAYNAME(`Date`) AS day_of_week,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings
FROM Bookings
WHERE `Date` IS NOT NULL
GROUP BY DAYOFWEEK(`Date`), DAYNAME(`Date`)
ORDER BY DAYOFWEEK(`Date`);

-- Q12. Which hours have the most bookings?
SELECT
    HOUR(`Time`) AS booking_hour,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings
FROM Bookings
WHERE `Time` IS NOT NULL
GROUP BY HOUR(`Time`)
ORDER BY booking_hour;

-- Q13. What is the successful booking rate by hour?
-- Compare rates with total bookings; small groups can produce unstable percentages.
SELECT
    HOUR(`Time`) AS booking_hour,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings,
    ROUND(SUM(Booking_Status = 'Success') * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS success_rate_pct
FROM Bookings
WHERE `Time` IS NOT NULL
GROUP BY HOUR(`Time`)
ORDER BY success_rate_pct DESC;

-- =========================================================
-- SECTION 4: CANCELLATIONS AND INCOMPLETE RIDES
-- =========================================================

-- Q14. What cancellation reasons are recorded for customers and drivers?
-- This counts non-null cancellation-field entries; it is not necessarily a count
-- of unique cancelled bookings if the source has inconsistent flags.
SELECT
    'Customer' AS cancellation_type,
    Canceled_Rides_by_Customer AS cancellation_reason,
    COUNT(*) AS records_with_reason
FROM Bookings
WHERE Canceled_Rides_by_Customer IS NOT NULL
  AND TRIM(Canceled_Rides_by_Customer) <> ''
GROUP BY Canceled_Rides_by_Customer

UNION ALL

SELECT
    'Driver' AS cancellation_type,
    Canceled_Rides_by_Driver AS cancellation_reason,
    COUNT(*) AS records_with_reason
FROM Bookings
WHERE Canceled_Rides_by_Driver IS NOT NULL
  AND TRIM(Canceled_Rides_by_Driver) <> ''
GROUP BY Canceled_Rides_by_Driver
ORDER BY records_with_reason DESC;

-- Q15. What reasons are recorded for incomplete rides?
-- Check Q6 first. This query assumes the flag value is exactly 'Yes'.
SELECT
    Incomplete_Rides_Reason,
    COUNT(*) AS incomplete_bookings
FROM Bookings
WHERE Incomplete_Rides = 'Yes'
GROUP BY Incomplete_Rides_Reason
ORDER BY incomplete_bookings DESC;

-- Q16. What percentage of records are marked as incomplete?
SELECT
    COUNT(*) AS total_bookings,
    SUM(Incomplete_Rides = 'Yes') AS incomplete_bookings,
    ROUND(SUM(Incomplete_Rides = 'Yes') * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS incomplete_rate_pct
FROM Bookings;

-- Q17. What cancellation statuses exist, and how common are they?
-- This uses Booking_Status directly and includes all status categories in the output.
SELECT
    Booking_Status,
    COUNT(*) AS total_bookings,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM Bookings), 0), 2)
        AS percentage_of_all_bookings
FROM Bookings
WHERE Booking_Status LIKE '%Cancel%'
GROUP BY Booking_Status
ORDER BY total_bookings DESC;

-- Q18. What is the cancellation rate by vehicle type?
-- Definition: statuses containing 'Cancel' count as cancelled. Other outcomes
-- such as 'Driver Not Found' are not included in this cancellation definition.
SELECT
    Vehicle_Type,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status LIKE '%Cancel%') AS cancelled_bookings,
    ROUND(SUM(Booking_Status LIKE '%Cancel%') * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS cancellation_rate_pct
FROM Bookings
GROUP BY Vehicle_Type
ORDER BY cancellation_rate_pct DESC;

-- Q19. Which pickup locations have the highest cancellation rates?
-- Locations with fewer than 10 bookings are excluded to reduce tiny-sample effects.
SELECT
    Pickup_Location,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status LIKE '%Cancel%') AS cancelled_bookings,
    ROUND(SUM(Booking_Status LIKE '%Cancel%') * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS cancellation_rate_pct
FROM Bookings
GROUP BY Pickup_Location
HAVING COUNT(*) >= 10
ORDER BY cancellation_rate_pct DESC
LIMIT 10;

-- =========================================================
-- SECTION 5: VEHICLE AND LOCATION PERFORMANCE
-- =========================================================

-- Q20. Which vehicle types receive the most bookings, and how do success rates compare?
SELECT
    Vehicle_Type,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings,
    ROUND(SUM(Booking_Status = 'Success') * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS success_rate_pct
FROM Bookings
GROUP BY Vehicle_Type
ORDER BY total_bookings DESC;

-- Q21. Which pickup locations have the most bookings?
SELECT
    Pickup_Location,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings
FROM Bookings
GROUP BY Pickup_Location
ORDER BY total_bookings DESC
LIMIT 10;

-- Q22. Which drop locations have the most bookings?
SELECT
    Drop_Location,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings
FROM Bookings
GROUP BY Drop_Location
ORDER BY total_bookings DESC
LIMIT 10;

-- Q23. Which pickup-to-drop routes are most common?
SELECT
    Pickup_Location,
    Drop_Location,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings
FROM Bookings
GROUP BY Pickup_Location, Drop_Location
ORDER BY total_bookings DESC
LIMIT 10;

-- =========================================================
-- SECTION 6: BOOKING VALUE, PAYMENT METHODS AND DISTANCE
-- =========================================================

-- Q24. What is the recorded booking value by vehicle type for successful bookings?
-- This is recorded booking value, not verified collected revenue or profit.
SELECT
    Vehicle_Type,
    COUNT(*) AS successful_bookings,
    COUNT(Booking_Value) AS bookings_with_value,
    ROUND(SUM(Booking_Value), 2) AS total_recorded_booking_value,
    ROUND(AVG(Booking_Value), 2) AS average_recorded_booking_value
FROM Bookings
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY total_recorded_booking_value DESC;

-- Q25. Which payment methods are most frequently recorded for successful bookings?
SELECT
    Payment_Method,
    COUNT(*) AS successful_bookings,
    COUNT(Booking_Value) AS bookings_with_value,
    ROUND(SUM(Booking_Value), 2) AS total_recorded_booking_value
FROM Bookings
WHERE Booking_Status = 'Success'
GROUP BY Payment_Method
ORDER BY successful_bookings DESC;

-- Q26. How does average ride distance vary by vehicle type?
SELECT
    Vehicle_Type,
    COUNT(*) AS successful_bookings,
    COUNT(Ride_Distance) AS bookings_with_distance,
    ROUND(AVG(Ride_Distance), 2) AS average_ride_distance,
    ROUND(SUM(Ride_Distance), 2) AS total_recorded_ride_distance
FROM Bookings
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY average_ride_distance DESC;

-- Q27. How many successful bookings fall into each booking-value range?
-- COUNT(*) = number of successful bookings in each band.
-- AVG(Booking_Value) = average value within that band.
-- These bands are analysis choices and can be adjusted.
SELECT
    CASE
        WHEN Booking_Value < 100 THEN 'Below 100'
        WHEN Booking_Value < 300 THEN '100 to 299.99'
        WHEN Booking_Value < 500 THEN '300 to 499.99'
        ELSE '500 and above'
    END AS booking_value_range,
    COUNT(*) AS number_of_bookings,
    ROUND(AVG(Booking_Value), 2) AS average_booking_value
FROM Bookings
WHERE Booking_Value IS NOT NULL
  AND Booking_Status = 'Success'
GROUP BY booking_value_range
ORDER BY MIN(Booking_Value);

-- Q28. How does successful recorded booking value change month by month?
SELECT
    DATE_FORMAT(`Date`, '%Y-%m') AS booking_month,
    COUNT(*) AS total_bookings,
    SUM(Booking_Status = 'Success') AS successful_bookings,
    ROUND(
        SUM(CASE
                WHEN Booking_Status = 'Success' THEN COALESCE(Booking_Value, 0)
                ELSE 0
            END),
        2
    ) AS successful_recorded_booking_value
FROM Bookings
WHERE `Date` IS NOT NULL
GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY booking_month;

-- =========================================================
-- SECTION 7: CUSTOMER AND DRIVER EXPERIENCE
-- =========================================================

-- Q29. What is the average customer rating by vehicle type?
-- AVG ignores NULL ratings. rated_bookings shows the valid-rating sample size.
SELECT
    Vehicle_Type,
    COUNT(*) AS successful_bookings,
    COUNT(Customer_Rating) AS rated_bookings,
    SUM(Customer_Rating IS NULL) AS missing_customer_ratings,
    ROUND(AVG(Customer_Rating), 2) AS average_customer_rating
FROM Bookings
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY average_customer_rating DESC;

-- Q30. What is the average driver rating by vehicle type?
SELECT
    Vehicle_Type,
    COUNT(*) AS successful_bookings,
    COUNT(Driver_Ratings) AS rated_bookings,
    SUM(Driver_Ratings IS NULL) AS missing_driver_ratings,
    ROUND(AVG(Driver_Ratings), 2) AS average_driver_rating
FROM Bookings
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY average_driver_rating DESC;

-- Q31. How do customer ratings vary by booking status?
-- A NULL average means no non-null ratings are available for that status.
SELECT
    Booking_Status,
    COUNT(*) AS total_bookings,
    COUNT(Customer_Rating) AS rated_bookings,
    SUM(Customer_Rating IS NULL) AS missing_customer_ratings,
    ROUND(AVG(Customer_Rating), 2) AS average_customer_rating
FROM Bookings
GROUP BY Booking_Status
ORDER BY average_customer_rating DESC;

-- Q32. How many turnaround-time measurements exist, and what are their averages?
-- Confirm the business definition and units of V_TAT/C_TAT before interpreting.
SELECT
    Booking_Status,
    COUNT(*) AS total_bookings,
    COUNT(V_TAT) AS vehicle_tat_records,
    SUM(V_TAT IS NULL) AS missing_vehicle_tat_records,
    ROUND(AVG(V_TAT), 2) AS average_vehicle_tat,
    COUNT(C_TAT) AS customer_tat_records,
    SUM(C_TAT IS NULL) AS missing_customer_tat_records,
    ROUND(AVG(C_TAT), 2) AS average_customer_tat
FROM Bookings
GROUP BY Booking_Status
ORDER BY Booking_Status;

-- =========================================================
-- SECTION 8: CUSTOMER ACTIVITY
-- =========================================================

-- Q33. How many customers have more than one booking in this dataset?
-- This is repeat booking during the dataset period, not a lifetime loyalty measure.
SELECT
    COUNT(*) AS customers_with_valid_customer_id,
    SUM(bookings_per_customer > 1) AS repeat_customers,
    ROUND(
        SUM(bookings_per_customer > 1) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_pct
FROM (
    SELECT
        Customer_ID,
        COUNT(*) AS bookings_per_customer
    FROM Bookings
    WHERE Customer_ID IS NOT NULL
      AND TRIM(Customer_ID) <> ''
    GROUP BY Customer_ID
) AS customer_booking_summary;

-- =========================================================
-- SECTION 9: OPTIONAL DATA QUALITY FOLLOW-UP
-- =========================================================

-- Q34. Are any numeric fields negative?
-- Negative values may be valid in some specialised datasets, but should be reviewed.
SELECT
    SUM(Booking_Value < 0) AS negative_booking_values,
    SUM(Ride_Distance < 0) AS negative_ride_distances,
    SUM(V_TAT < 0) AS negative_vehicle_tat,
    SUM(C_TAT < 0) AS negative_customer_tat
FROM Bookings;

-- Q35. Are ratings outside a common 1-to-5 scale?
-- Review the source's documented rating scale before treating these as errors.
SELECT
    SUM(Customer_Rating < 1 OR Customer_Rating > 5) AS customer_ratings_outside_1_to_5,
    SUM(Driver_Ratings < 1 OR Driver_Ratings > 5) AS driver_ratings_outside_1_to_5
FROM Bookings;

-- =========================================================
-- END OF ANALYSIS
-- =========================================================
