-- P1: Monthly active borrowers, split into new and returning
-- Database: kutubxona_v2.sqlite
-- Why: shows whether the library grows by attracting new members or by keeping existing ones
-- Definition: active borrower in a month = member with >= 1 loan that month.
--             New = the month of the member's first loan ever; returning = borrowed in an earlier month.

WITH first_month AS(
SELECT member_id, MIN(STRFTIME('%Y-%m', loan_date)) AS first_month
FROM library_loan
GROUP BY member_id),
 active_month AS( 
SELECT  DISTINCT member_id, STRFTIME('%Y-%m', loan_date) AS loan_month
FROM library_loan)
SELECT a.loan_month,
		 COUNT(*) AS active_borrowers, 
		 SUM(CASE WHEN f.first_month=a.loan_month THEN 1 ELSE 0 END)  AS new_borrowers, 
		 SUM(CASE WHEN a.loan_month>f.first_month THEN 1 ELSE 0 END)  AS returning_borrowers
FROM first_month AS f
JOIN active_month AS a
ON f.member_id=a.member_id
GROUP BY loan_month
ORDER BY loan_month;


-- Result: active borrowers grew from 5 (2024-12) to 140 (2026-10).
--         New borrowers were the majority only in the first 3 months; from month 4, returning borrowers are the majority.
--         Summer dip: clear in 2026 (June-August, 121-> 101); weak in 2025 (about -4),
--         probably hidden by fast growth in the first year.
-- Check: new + returning = active in every row; SUM(new_borrowers) = 365 = distinct borrowers.
--        35 of 400 members (9%) never borrowed.
-- Note: the last month (2026-11) is incomplete, so its low number is not a real drop.