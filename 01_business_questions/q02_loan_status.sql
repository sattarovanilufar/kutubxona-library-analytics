-- Q2: How many loans are Returned, Active, and Overdue?
-- Why: the most basic health check of the library.
-- Result (v2, as of 2026-11-10): 3,326 returned, 128 active, 25 overdue (total 3,479).
-- Check: 3,326 + 128 + 25 = 3,479 = all loans.
-- Note: the data stops on 2026-11-10, so "today" = the last loan date (as-of date), not date('now').
--       With date('now') on 2026-11-26, all 128 active loans looked overdue (153 instead of 25).
--       CROSS JOIN is intended here: as_of has exactly 1 row, so it adds the as-of date to every loan.
WITH as_of AS (
	SELECT MAX(loan_date) AS d 
	FROM library_loan)
SELECT COUNT(CASE
			WHEN return_date IS NULL AND due_date<d THEN 1
			END) AS overdue,
		 COUNT( CASE 
		 	WHEN return_date IS NOT NULL THEN 1
			END) AS returned,
		 COUNT( CASE
		   WHEN return_date IS NULL AND due_date>=d THEN 1
			END) AS active_loan,
		 COUNT(*) AS total_loan
FROM library_loan
CROSS JOIN as_of;
