-- Q10: Average days a book is kept, per category (returned loans only, >= 3 loans).
-- Why: shows which categories people keep longest; helps decide loan periods and extra copies.
-- Result (v2): all categories are between 11.4 days (Poetry) and 12.4 days (History & Society).
-- Insight: category hardly matters; members keep books about 12 days, under the 14-day loan period,
--          so one loan period for all categories is fine.
-- Check: returned loans add up to 3,326 = returned loans in q02.
-- Note: on the small database the range looked big (8.5-14.7 days, 7 loans): small-sample noise.
-- Why returned loans only: unreturned loans have no end date yet (censored data).
--   Using today's date instead would underestimate, because those books will be kept longer.
SELECT category.name, ROUND(AVG(julianday(loan.return_date) - julianday(loan.loan_date)), 1) AS avg_days, COUNT(*) AS returned_loans
FROM library_loan AS loan
JOIN library_book AS book 
ON loan.book_id=book.id
JOIN library_category AS category
ON book.category_id=category.id
WHERE loan.return_date IS NOT NULL
GROUP BY category.id
HAVING COUNT(*)>=3
ORDER BY avg_days DESC;
