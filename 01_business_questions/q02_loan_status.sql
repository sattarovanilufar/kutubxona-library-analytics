-- Q2: How many loans are Returned, Active, and Overdue?
-- Why: the most basic health check of the library.
-- My version 
SELECT COUNT(CASE
			WHEN return_date IS NULL AND due_date<date('now', 'localtime') THEN 1
			END) AS Overdue,
		 COUNT( CASE 
		 	WHEN return_date IS NOT NULL THEN 1
			END) AS Returned,
		 COUNT( CASE
		   WHEN return_date IS NULL AND due_date>=date('now', 'localtime') THEN 1
			END) AS Active_loan,
		 COUNT(*) AS total_loan
FROM library_loan;
-- Alternative 
--SELECT CASE
 --          WHEN return_date IS NOT NULL                 THEN 'Returned'
 --          WHEN due_date < date('now', 'localtime')     THEN 'Overdue'
 --          ELSE 'Active'
 --      END      AS status,
 --      COUNT(*) AS loans
--FROM library_loan
--GROUP BY status
--ORDER BY loans DESC;