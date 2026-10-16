--Q5: How many loans happened in each month?
--Why: is the library getting busier? This is the classic trend question.
SELECT STRFTIME('%Y-%m', loan_date) AS month, COUNT(*) AS number_of_loans
FROM library_loan
GROUP BY month
ORDER BY MONTH;
-- Result: from 2025-12 to 2026-10; the busiest months are 2026-03, 2026-10 (7 loans).