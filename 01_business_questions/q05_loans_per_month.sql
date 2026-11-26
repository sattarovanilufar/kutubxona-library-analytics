--Q5: How many loans happened in each month?
--Why: is the library getting busier? This is the classic trend question.
-- Result (v2): loans grew from 33 (2025-01) to 267 (2026-10); the busiest month is 2026-09 (269).
--         Summer dip in 2026: 241 (May) -> 173 (June), -28%; a small dip in 2025 too (98 -> 72).
-- Check: same numbers as the monthly chart in 05_python_analysis.
-- Note: 2026-11 (153) covers only 1-10 Nov, because the data stops on 2026-11-10; don't compare it with full months.
--       2024-12 (12) is the library's first month (from 6 Dec).
SELECT STRFTIME('%Y-%m', loan_date) AS month, COUNT(*) AS number_of_loans
FROM library_loan
GROUP BY month
ORDER BY month;
