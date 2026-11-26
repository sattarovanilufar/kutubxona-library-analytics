-- Q3:List all overdue loans with member name, book title, and days late, worst first.
--Why: the librarian needs a call LIST.
-- Result (v2, as of 2026-11-10): 25 overdue loans; the worst is 21 days late (due 2026-10-20).
-- Check: 25 = the overdue count in q02.
-- Note: days_late is counted from the as-of date (last loan date), not date('now'), because the data stops on 2026-11-10.
--       Some members have 2+ overdue books (same phone), so the librarian needs fewer than 25 calls.
--       Two different members can share a name (Jasur Raximov), so identify people by id/phone, not by name.
--       julianday() is needed, because subtracting text dates gives wrong numbers.
WITH as_of AS (
	SELECT MAX(loan_date) AS d 
	FROM library_loan)
SELECT  member.first_name || ' ' || member.last_name AS full_name, member.phone, book.title AS book_title, loan.due_date, CAST(julianday(d)-julianday(loan.due_date) AS INTEGER)  AS days_late
FROM library_loan AS loan
JOIN library_member AS member
ON loan.member_id=member.id
JOIN library_book AS book
ON loan.book_id=book.id
CROSS JOIN as_of
WHERE loan.return_date IS NULL AND loan.due_date<d
ORDER BY days_late DESC;
