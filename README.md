# Kutubxona Library Analytics

End-to-end analysis of a library management database: SQL, data cleaning,
product metrics and Python visualisation.

**Data:** the database comes from my own Django app "Kutubxona" (library system).
For Sections 2–5 I use a larger synthetic version (400 members, ~3,000 loans over
2 years) generated with a script (see `data/`), plus a "messy" copy with planted
errors for cleaning practice.

## Sections
| # | Folder | Skills | Status |
|---|---|---|---|
| 1 | `01_business_questions/` | JOINs, CASE, dates, conditional aggregation | ✅ done |
| 2 | `02_window_functions/` | ROW_NUMBER, RANK, LAG/LEAD, running totals | ✅ done |
| 3 | `03_data_cleaning/` | finding and fixing data quality issues | (coming soon) |🔄 in progress |
| 4 | `04_product_metrics/` | active users, cohort retention, funnel | (coming soon) |
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

## Key findings
*(added after Section 5)*

## Tools
SQLite, HeidiSQL, Python (pandas, seaborn), Git