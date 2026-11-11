-- Q3:List all overdue loans with member name, book title, and days late, worst first.
--Why: the librarian needs a call LIST.
SELECT member.first_name || ' ' || member.last_name AS full_name, member.phone, book.title AS book_title, loan.due_date, CAST(julianday(DATE('now', 'localtime'))-julianday(loan.due_date) AS INTEGER)  AS days_late
FROM library_loan AS loan
JOIN library_member AS member
ON loan.member_id=member.id
JOIN library_book AS book
ON loan.book_id=book.id
WHERE loan.return_date IS NULL AND loan.due_date<DATE('now', 'localtime')
ORDER BY days_late DESC;
-- Result: 7 overdue loans; the worst is 49 days late.
-- Note: days_late changes every day because it uses today's date.
--       julianday() is needed, because subtracting text dates gives wrong numbers.
