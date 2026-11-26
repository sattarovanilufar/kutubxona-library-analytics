-- Q1: How many books in each category?
-- Why: shows which shelves are big and which are small.
SELECT category."name", COUNT(book.id) AS book_per_category
FROM library_category AS category
LEFT JOIN library_book AS book
ON category.id=book.category_id
GROUP BY category."name", category.id
ORDER BY book_per_category DESC;
-- Result (v2): 6 categories; the biggest is World Classics (10 books), the smallest is Poetry (3 books).
-- Check: 10+8+6+5+4+3 = 36 = all books in v2.
-- Note: LEFT JOIN + COUNT(book.id), so a category with 0 books still shows 0.