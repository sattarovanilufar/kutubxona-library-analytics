-- Q10: Average days a book is kept, per category (returned loans only, >= 3 loans).
-- Why: shows which categories people keep longest; helps decide loan periods and extra copies.
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
-- Result (run on 2026-10-16): longest is History&Society (14.7 days, 7 loans), shortest is World classics (8.5 days).
-- Why returned loans only: unreturned loans have no end date yet (censored data).
--   Using today's date instead would underestimate, because those books will be kept longer.
