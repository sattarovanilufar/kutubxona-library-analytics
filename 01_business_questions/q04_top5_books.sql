--Q4: What are the 5 most borrowed books?
--Why: to decide which books need extra copies.
-- Result (v2): #1 O'tkan kunlar (228 loans), then Dunyoning ishlari (186), Shum bola (183), Sapiens (165), The Alchemist (152).
-- Check: same as the top of the bar chart in 05_python_analysis; #6 has 148, so no tie at place 5.
-- Note: for buying copies, loans per copy is a better measure than total loans
--       (Sapiens: 27.5 loans per copy vs O'tkan kunlar: 22.8), see Key finding 5.
SELECT book.title, COUNT(loan.book_id) AS times_borrowed
FROM library_loan AS loan
JOIN library_book AS book
ON loan.book_id=book.id
GROUP BY book.id, book.title
ORDER BY times_borrowed DESC, book.title
LIMIT 5;  

