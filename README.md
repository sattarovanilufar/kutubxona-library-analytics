# Kutubxona Library Analytics

End-to-end analysis of a library management database: SQL, data cleaning,
product metrics and Python visualisation.

**Data:** the database comes from my own Django app "Kutubxona" (library system).
For Sections 2–5 I use a larger synthetic version (400 members, 36 books, 3,479 loans
over ~2 years) generated with a script (see `data/`), plus a "messy" copy with planted
errors for cleaning practice. The synthetic data has built-in patterns (growth,
a summer dip, students returning late more often, an online reservation feature
launched in January 2026), so the numbers are realistic but not real.

## Sections
| # | Folder | Skills | Status |
|---|---|---|---|
| 1 | `01_business_questions/` | JOINs, CASE, dates, conditional aggregation | ✅ done |
| 2 | `02_window_functions/` | ROW_NUMBER, RANK, LAG/LEAD, running totals | ✅ done |
| 3 | `03_data_cleaning/` | finding and fixing data quality issues, clean views | ✅ done |
| 4 | `04_product_metrics/` | active users, cohort retention, funnel | ✅ done |
| 5 | `05_python_analysis/` | pandas, seaborn, final insights | (coming soon) |

Each `.sql` file starts with a comment block: the business question, why it matters,
the result, and notes on how I checked it.

## 1. Business questions
1. How many books are in each category?
2. How many loans are returned, active and overdue?
3. Overdue call list: who to phone, and how many days late?
4. Which 5 books are borrowed most?
5. How many loans per month? (trend)
6. Which members have never borrowed a book?
7. How many books and loans per author?
8. Late rate by membership type
9. Fines: paid vs unpaid, and which members owe the most
10. Average days a book is kept, per category

## 2. Window functions
All 10 queries are in `02_window_functions/window_functions.sql`.
1. Number each member's loans in time order
2. Each member's first loan (name, date, book)
3. Top 3 most borrowed books in each category
4. Days since the same member's previous loan
5. Loans per month and % change vs the previous month
6. Running total of loans by month
7. 3-month moving average of monthly loans
8. Each book's share of its category's loans
9. Members in quartiles by activity: how much does the most active 25% borrow?
10. % of members who borrow again within 30 days of their first loan, by membership type

## 3. Data cleaning
Checks in `03_data_cleaning/cleaning.sql`, every issue in `03_data_cleaning/data_issues_log.md`.
1. Ran 6 checks on every table: size, categories, missing values, format, duplicates, logic
2. Found and logged 14 data quality issues with row counts (e.g. 12 duplicate members, 40 duplicate loans, 25 dates in the wrong format, 6 orphan loans)
3. Built `member_clean` view: trimmed and standardised names, emails, membership types, dates and phones; one row per person (412 -> 400 rows)
4. Built `loan_clean` view: fixed dates, removed duplicates, impossible returns and orphan loans (3,519 -> 3,461 rows)
5. Checked every view after cleaning (row counts reconciled, all checks return 0)

## 4. Product metrics
1. Monthly active borrowers, split into new and returning (`active_borrowers.sql`)
2. Monthly cohort retention: % of each join-month cohort borrowing 0–12 months later (`cohort_retention.sql`)
3. Reservation funnel: placed -> fulfilled -> borrowed within 30 days (`funnel.sql`)

## Key findings
*(added after Section 5)*

## Tools
SQLite, HeidiSQL, Python (pandas, seaborn), Git