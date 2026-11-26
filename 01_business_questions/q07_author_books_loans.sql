--Q7: For each author: how many books, and how many loans of their books?
--Why: which authors should we buy more of?
-- Result (v2): 24 authors; the top author is O'tkir Hoshimov (3 books, 392 loans), then Abdulla Qodiriy (2 books, 351).
-- Check: books add up to 38 (not 36) and loans to 3,602 (not 3,479), because 2 books have 2 authors:
--        Levitt + Dubner (84 loans) and Hawking + Mlodinow (39 loans); 84 + 39 = 123 = 3,602 - 3,479.
-- Note: COUNT(DISTINCT book_id) avoids the fan-out trap.
--       Co-authored books count fully for each author, so don't add up the loans column.
SELECT author.first_name || ' ' || author.last_name AS full_name, COUNT(DISTINCT b_a.book_id) AS number_of_books, COUNT(loan.id) AS number_of_loans
FROM library_author AS author
JOIN library_book_authors AS b_a
ON author.id=b_a.author_id
LEFT JOIN library_loan AS loan
ON  b_a.book_id=loan.book_id
GROUP BY author.id, full_name
ORDER BY number_of_loans DESC;