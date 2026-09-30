# Ola/Uber Ride Booking Analysis

SQL analysis of 103,024 ride bookings to find where the platform is losing rides (cancellations, driver mismatches) and why.

## What's in this repo
- `01_ola_uber_booking_analysis.sql` — full script: table setup, data load with cleaning, 9 validation checks, and 26 business-question queries across booking performance, cancellations, vehicle/location performance, booking value, ratings, and repeat customers.
- `Ride_Analysis_Documentation.docx` — full write-up: what I did, problems I hit while loading the data, and the confirmed findings so far.

## Dataset
Ola & Uber Ride Booking & Cancellation Data (Kaggle), ~103,000 India-based ride bookings.

## Status so far
- Data loaded and validated: 103,024 rows, zero duplicate Booking_IDs, unique constraint added.
- Booking outcome breakdown confirmed:
  - Success: 63,967 (62.09%)
  - Canceled by Driver: 18,434 (17.89%)
  - Canceled by Customer: 10,499 (10.19%)
  - Driver Not Found: 10,124 (9.83%)
- Remaining business-question queries (cancellation reasons, vehicle/location performance, booking value, ratings, repeat customers) are written and ready to run; findings to be added as I go.

## Tools
MySQL, Excel, Power BI (dashboard in progress).

(Used Claude AI as a guide while writing and debugging the SQL — the questions, analysis, and findings are my own work.)


 ##  ![Dashboard](dashboard.png)

 The Power BI dashboard file (.pbix) exceeds GitHub's 25 MB file size limit and is not included in this repository. A screenshot of the visual report is provided above for reference.
 
   

