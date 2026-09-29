# Ola/Uber Ride Booking Analysis — Project Notes

**Author:** Rahul Ballidav  
**Tools:** MySQL Workbench, Power BI  
**Dataset table:** `Bookings`

## 1. Project goal

Use ride-booking records to understand booking outcomes, demand patterns, cancellations, incomplete rides, vehicle and location patterns, recorded booking value, payment methods, ratings, turnaround-time fields, and repeat booking.

The analysis identifies patterns to investigate. It does not automatically prove why a pattern occurs.

## 2. Dataset grain and columns

The intended grain is one row per booking. Validate this using the `Booking_ID` duplicate query and separately check missing/blank IDs.

Key fields:
- `Date`, `Time`: booking date and time
- `Booking_ID`, `Customer_ID`: booking and customer identifiers
- `Booking_Status`: recorded booking outcome
- `Vehicle_Type`, `Pickup_Location`, `Drop_Location`: vehicle and route context
- `V_TAT`, `C_TAT`: turnaround-time fields; verify their definitions and units
- `Canceled_Rides_by_Customer`, `Canceled_Rides_by_Driver`: recorded cancellation fields/categories
- `Incomplete_Rides`, `Incomplete_Rides_Reason`: incomplete-ride flag and reason
- `Booking_Value`: recorded value associated with a booking; not necessarily collected revenue or profit
- `Payment_Method`, `Ride_Distance`, `Driver_Ratings`, `Customer_Rating`: payment, distance and rating fields

## 3. How to run the SQL script

1. Confirm `bookings.csv` is in the MySQL server's configured `Uploads` folder.
2. Open `01_ola_uber_booking_analysis.sql` in MySQL Workbench.
3. **Important:** The setup section uses `DROP TABLE IF EXISTS Bookings`. Running the full script rebuilds the table and replaces its existing contents.
4. Run the script from the top if you intend to rebuild the table. If the table is already loaded and you only want to repeat analysis, select and run the relevant query sections starting at `SECTION 2: DATA VALIDATION`.
5. Inspect Q1 for exact `Booking_Status` values and Q6 for exact `Incomplete_Rides` values before interpreting queries that filter on `'Success'`, `'Yes'`, or statuses containing `'Cancel'`.
6. Save actual query results separately for the final findings. Do not invent values in the README.

## 4. Business questions and what each answer tells us

| Question | Business question | What the SQL output tells us |
|---|---|---|
| Q1 | What booking statuses exist? | Status categories and booking counts |
| Q2 | How many records are present? | Dataset row count |
| Q3 | Are booking IDs duplicated? | Repeated non-blank IDs, if any |
| Q4 | Are key fields missing? | Missing-value counts for important columns |
| Q5 | What period and coverage do we have? | Date range, distinct dates, customers and vehicle types |
| Q6 | What values exist in the incomplete flag? | Exact values to use in incomplete-ride filters |
| Q7 | Which payment methods are recorded? | Counts by payment method |
| Q8 | What share of bookings belongs to each status? | Counts and percentage distribution |
| Q9 | What is the successful booking rate? | Successful bookings as a percentage of all bookings |
| Q10 | How do bookings change by month? | Monthly total and successful booking counts |
| Q11 | Which weekdays are busiest? | Booking and successful booking counts by weekday |
| Q12 | Which hours are busiest? | Booking counts by hour |
| Q13 | How does success rate vary by hour? | Success percentage and sample size by hour |
| Q14 | What cancellation reasons are recorded? | Counts of non-null customer/driver cancellation entries |
| Q15 | Why are rides marked incomplete? | Counts by recorded incomplete-ride reason |
| Q16 | What share of bookings is marked incomplete? | Incomplete-ride count and percentage |
| Q17 | Which statuses contain “Cancel”? | Cancellation status counts and shares among cancellation-status rows |
| Q18 | How does cancellation rate vary by vehicle? | Cancel-status count and percentage by vehicle type |
| Q19 | Which pickup locations have high cancellation rates? | Location-level cancellation rates for locations with at least 10 bookings |
| Q20 | Which vehicle types receive bookings and succeed? | Bookings, successful counts and success rates by vehicle type |
| Q21 | Where do pickups happen most often? | Top pickup locations |
| Q22 | Where do rides end most often? | Top drop locations |
| Q23 | Which routes are most common? | Top pickup/drop pairs |
| Q24 | What is recorded booking value by vehicle? | Total and average recorded value for successful bookings |
| Q25 | Which payment methods are used most? | Successful booking counts and recorded value by payment method |
| Q26 | How does distance vary by vehicle? | Average and total recorded ride distance |
| Q27 | How many successful bookings fall into value bands? | Number of bookings and average value per band |
| Q28 | How does successful booking value change monthly? | Monthly successful booking counts and recorded value |
| Q29 | How do customer ratings vary by vehicle? | Average rating, number rated and missing ratings |
| Q30 | How do driver ratings vary by vehicle? | Average rating, number rated and missing ratings |
| Q31 | How do customer ratings vary by status? | Average rating and rating availability by booking status |
| Q32 | What turnaround-time data is available? | Measurement counts, missing counts and averages by status |
| Q33 | How many customers book more than once? | Unique valid customer IDs and repeat-booking share |
| Q34 | Are numeric fields negative? | Counts of potentially anomalous negative values |
| Q35 | Are ratings outside 1–5? | Counts of values outside a common rating scale; verify source scale |

## 5. Explanations for common results

### Q3 returns no rows
That is usually a good result: no non-blank `Booking_ID` was found more than once. It does not prove that there are no missing IDs; Q4 checks those separately.

### Q4 returns one summary row
An aggregate query using `SUM()` without `GROUP BY` returns one row. Zero means no missing values were found for that field. If the result appears blank, confirm the full query was executed and check the result grid.

### Q27 — value ranges
The bands are chosen for analysis:
- Below 100
- 100 to 299.99
- 300 to 499.99
- 500 and above

`COUNT(*)` is the number of successful bookings with a non-null `Booking_Value` in each band. `AVG(Booking_Value)` is the average value of those bookings. These bands are not official fare categories and can be changed.

### Q31 — NULL average customer rating
`AVG()` ignores NULL values. If a status has no non-null customer ratings, its average is NULL, not zero. `COUNT(Customer_Rating)` shows the number of available ratings; `SUM(Customer_Rating IS NULL)` shows missing ratings.

### Q32 — NULL turnaround-time averages
If all turnaround-time values in a status group are NULL, the average is NULL. `COUNT(V_TAT)` and `COUNT(C_TAT)` count non-null measurements. Confirm the definitions and units of these fields before describing the averages as minutes.

## 6. Important interpretation limits

- A recorded `Booking_Value` is not automatically collected revenue, profit, or net revenue.
- The success rate depends on the dataset's exact success status label.
- The cancellation queries that use `Booking_Status LIKE '%Cancel%'` count only statuses containing “Cancel”; other outcomes such as “Driver Not Found” are separate outcomes, not automatically cancellations.
- Cancellation reason fields and booking status may not be perfectly consistent. Compare them before reporting a definitive cancellation count.
- Repeat customer percentage measures repeat booking in this dataset's time window, not lifetime loyalty.
- `AVG()` ignores NULL values; always inspect sample sizes when comparing ratings or turnaround times.
- Observational patterns do not establish causation. Say “associated with” or “worth investigating” rather than claiming a factor caused an outcome without further evidence.
- Check the rating scale, turnaround-time units, and value definitions against the dataset documentation.

## 7. How to write findings after running the queries

For each important finding, record:
1. **Question:** What business issue are we investigating?
2. **Metric:** What exactly did we calculate?
3. **Result:** Copy the actual number from MySQL.
4. **Interpretation:** What does the result show?
5. **Caveat:** What does it not prove?
6. **Follow-up:** What should the business investigate next?

Example template (replace all brackets with actual results):

> **Finding:** The successful booking rate was [X%] across [N] bookings.  
> **Interpretation:** [Describe the observed distribution neutrally.]  
> **Follow-up:** Review booking statuses and cancellation categories to understand which outcomes account for the remaining bookings.

## 8. Power BI dashboard plan

Suggested KPI cards:
- Total bookings
- Successful bookings
- Success rate
- Cancellation-status rate (define exactly which statuses count)
- Average customer rating
- Total recorded booking value for successful bookings

Suggested visuals:
- Monthly booking trend
- Booking status distribution
- Booking demand by hour and weekday
- Bookings and success rate by vehicle type
- Top pickup and drop locations
- Cancellation reasons and incomplete-ride reasons
- Recorded booking value by vehicle and payment method
- Customer and driver rating comparisons

Use filters/slicers for date, vehicle type, booking status, and pickup location where useful. Ensure each measure uses a clearly documented definition.

## 9. GitHub repository structure

```text
ola-uber-booking-analysis/
├── README.md
├── sql/
│   └── 01_ola_uber_booking_analysis.sql
├── powerbi/
│   └── ola_uber_analysis.pbix
└── screenshots/
    └── dashboard.png
```

Do not upload the full dataset unless redistribution is permitted. Add the dataset source and its usage terms to your README.
