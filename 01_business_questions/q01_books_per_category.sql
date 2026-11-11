-- Q1: How many books in each category?
-- Why: shows which shelves are big and which are small.
SELECT category."name", COUNT(book.id) AS Number_of_book_per_category
FROM library_category AS category
LEFT JOIN library_book AS book
ON category.id=book.category_id
GROUP BY category."name"
ORDER BY Number_of_book_per_category DESC;
-- Result: 6 categories; the biggest is Novel (6 books), the smallest is Children (2 books).
-- Note: LEFT JOIN + COUNT(book.id), so a category with 0 books still shows 0.