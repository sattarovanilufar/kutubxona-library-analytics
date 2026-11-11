--Q7: For each author: how many books, and how many loans of their books?
--Why: which authors should we buy more of?
SELECT author.first_name || ' ' || author.last_name AS full_name, COUNT(DISTINCT b_a.book_id) AS number_of_books, COUNT(loan.id) AS number_of_loans
FROM library_author AS author
JOIN library_book_authors AS b_a
ON author.id=b_a.author_id
left JOIN library_loan AS loan
ON  b_a.book_id=loan.book_id
GROUP BY author.id, full_name
ORDER BY number_of_loans DESC;
-- Result: the top author is Stephen Hawking(3 books, 10 loans).
-- Note: COUNT(DISTINCT book_id) avoids the fan-out trap.
--       Co-authored books count for each author, so the loans column adds up to more than 47.