# Ola/Uber Ride Booking Analysis

## Project Overview
This project uses MySQL and Power BI to analyse ride-booking outcomes, time trends, cancellations, vehicle and location patterns, recorded booking value, payment methods, ratings, turnaround-time fields, and repeat bookings.

## Business Problem
The analysis explores how bookings are distributed across statuses, when demand is highest, which cancellation categories are recorded, how results vary by vehicle and location, and how customer experience metrics vary. Results are descriptive and help identify areas for further investigation; they do not independently prove causes.

## Tools
- MySQL Workbench
- Power BI
- GitHub

## Analysis Workflow
1. Load the CSV data into MySQL.
2. Validate row counts, duplicate booking IDs, missing values, status values, and date coverage.
3. Analyse booking outcomes and time trends.
4. Examine cancellations and incomplete rides.
5. Compare vehicle types, pickup/drop locations, and common routes.
6. Analyse recorded booking value, payment methods, and ride distance.
7. Compare customer/driver ratings and turnaround-time fields.
8. Calculate repeat booking within the dataset period.
9. Build a Power BI dashboard.

## Key Findings
Complete this section only after reviewing actual query outputs:
- Total bookings: [insert actual result]
- Successful booking rate: [insert actual result]
- Most common booking status: [insert actual result]
- Most common cancellation category: [insert actual result]
- Most frequently booked vehicle type: [insert actual result]
- Most common pickup location: [insert actual result]
- Average customer rating: [insert actual result]
- Repeat customer percentage: [insert actual result]

## Limitations
- Recorded booking value is not necessarily collected revenue or profit.
- NULL ratings and turnaround-time fields affect the available sample size.
- Status-based cancellation rates count only statuses defined in the SQL query.
- Repeat booking is measured only within the dataset's date range.
- Observed patterns do not establish causation.

## Repository Structure
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

## Author
Rahul Ballidav — Aspiring Data Analyst

