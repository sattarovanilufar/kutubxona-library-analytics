--Q4: What are the 5 most borrowed books?
--Why: to decide which books need extra copies.
SELECT book.title, COUNT(loan.book_id) AS times_borrowed
FROM library_loan AS loan
JOIN library_book AS book
ON loan.book_id=book.id
GROUP BY book.id, book.title
ORDER BY times_borrowed DESC, book.title
LIMIT 5;  
-- Result: #1 is "A Brief History of Time" (5 loans).

