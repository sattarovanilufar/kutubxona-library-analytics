-- Kutubxona: Window functions (Section 2)
-- Database: kutubxona_v2.sqlite (400 members, ~3,000 loans)

-- W1: Number each member's loans in time order (1 = first loan).
SELECT member.first_name || ' ' || member.last_name AS full_name, loan.book_id, loan.loan_date, ROW_NUMBER() OVER(PARTITION BY member.id ORDER BY loan.loan_date, loan.id) AS loan_number
FROM library_member AS member
JOIN library_loan AS loan
ON member.id=loan.member_id
ORDER BY member.id, loan_number; 
-- Note: loan.id is a tie-breaker for two loans on the same day, so the numbering never changes between runs.

--W2: Show each member's first loan only: member name, date, and book title.
WITH ranked_loans AS(
SELECT member.first_name || ' ' || member.last_name AS full_name, book.title AS title, loan.loan_date AS  loan_date, ROW_NUMBER() OVER(PARTITION BY member.id ORDER BY loan.loan_date, loan.id) AS loan_number
FROM library_member AS member
JOIN library_loan AS loan
ON member.id=loan.member_id
JOIN library_book AS book
ON loan.book_id=book.id)
SELECT full_name, title, loan_date
FROM ranked_loans 
WHERE loan_number=1
ORDER BY full_name, loan_date;
-- Note: ROW_NUMBER (not RANK) guarantees exactly one row per member, even with ties.

-- W3: Top 3 most borrowed books in each category.
-- Why: shows which books need extra copies in each section of the library.
WITH counted_books AS(
SELECT category.name AS category_name, category.id AS category_id, book.title AS title, COUNT(loan.id) AS number_of_loans
FROM library_category AS category
JOIN library_book AS book
ON category.id=book.category_id
LEFT JOIN library_loan AS loan
ON book.id=loan.book_id
GROUP BY category.id, category.name, book.id, book.title),
	ranked_books AS(
SELECT  category_name, title, number_of_loans, DENSE_RANK() OVER(partition BY category_id ORDER BY number_of_loans DESC) AS rank_of_books
FROM counted_books)
SELECT category_name, title, number_of_loans, rank_of_books
FROM ranked_books
WHERE rank_of_books<=3
ORDER BY category_name, rank_of_books, title;
-- Note: DENSE_RANK keeps tied books, so a category can show more than 3 books. That's intended: equally popular books should both be considered.
-- Note: LEFT JOIN keeps books with 0 loans (they can still be in a small category's top 3).

-- W4: Days since the same member's previous loan.
-- Why: shows how often members come back (a "visit frequency" metric).
WITH loans_with_prev AS(
SELECT member_id, loan_date, LAG(loan_date) OVER(PARTITION BY member_id ORDER BY loan_date, id) AS prev_loan
FROM library_loan)
SELECT member_id, loan_date, prev_loan, CAST(JULIANDAY(loan_date)-JULIANDAY(prev_loan) AS integer) AS diff_since_prev_loan
FROM loans_with_prev
ORDER BY member_id, loan_date;
-- Note: the first loan of each member has NULL because there is no previous loan.
-- Note: id is a tie-breaker for loans on the same day.

-- W5: Loans per month and % change vs the previous month.
-- Why: the classic "is the library growing?" trend.
WITH extracted_month AS(
SELECT STRFTIME('%Y-%m', loan_date)  AS month, COUNT(id) AS loans_per_month
FROM library_loan
WHERE loan_date < date('now', 'localtime', 'start of month')
GROUP BY month),
	previous_month AS(
SELECT month, loans_per_month, LAG(loans_per_month) OVER( ORDER BY month) AS loans_prev_month
FROM extracted_month)
SELECT month, loans_prev_month, loans_per_month, ROUND(100.0*(loans_per_month-loans_prev_month)/loans_prev_month, 1) AS percentage_diff
FROM previous_month
ORDER BY month;
-- Note: the incomplete current month is excluded (a partial month always looks like a big drop).

-- W6: Running (cumulative) total of loans by month.
-- Why: shows total library usage over time ("how many loans so far").
WITH extracted_month AS(
SELECT STRFTIME('%Y-%m', loan_date)  AS month, COUNT(id) AS loans_per_month
FROM library_loan
GROUP BY month)
SELECT month, loans_per_month, SUM(loans_per_month) OVER(ORDER BY month) AS running_total
FROM extracted_month
ORDER BY month;
-- Check: the last running total = COUNT(*) of all loans (3479). Matches.

-- W7: 3-month moving average of monthly loans.
-- Why: smooths monthly ups and downs, so the real trend is easier to see.
WITH extracted_month AS(
SELECT STRFTIME('%Y-%m', loan_date)  AS month, COUNT(id) AS loans_per_month
FROM library_loan
WHERE loan_date < date('now', 'localtime', 'start of month')
GROUP BY month)
SELECT month, loans_per_month, 
		CASE WHEN COUNT(*) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) < 3 THEN NULL 
		ELSE ROUND(AVG(loans_per_month) OVER(ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ), 1) 
		END AS moving_avg_3m
FROM extracted_month
ORDER BY month;
-- Note: the first 2 months show NULL (fewer than 3 months of data in the window).
-- Note: the incomplete current month is excluded.

-- W8: Each book's share (%) of its category's total loans.
-- Why: shows if a category depends on one or two "star" books.
WITH counted_books AS(
SELECT category.name AS category_name, category.id AS category_id, book.title AS book_title, COUNT(loan.id) AS number_of_loans
FROM library_category AS category
JOIN library_book AS book
ON category.id=book.category_id
LEFT JOIN library_loan AS loan
ON book.id=loan.book_id
GROUP BY category.id, category.name, book.id, book.title),
	sum_of_loans_per_category AS(
SELECT category_name, book_title, number_of_loans,  SUM(number_of_loans) OVER(PARTITION BY category_id) AS category_total
FROM counted_books)
SELECT category_name, book_title, number_of_loans, category_total, ROUND(100.0*number_of_loans/category_total, 1) AS book_share
FROM sum_of_loans_per_category
ORDER BY category_name, book_share DESC;

-- W9: Members split into 4 quartiles by number of loans (including members with 0).
-- Why: checks whether a small group of active members makes most of the loans (80/20 rule).
WITH loans_per_member AS(
SELECT member.id AS member_id, COUNT(loan.id)  AS member_loans
FROM library_member AS member
LEFT JOIN library_loan AS loan
ON member.id=loan.member_id
GROUP BY member.id),
	member_quartiles AS(
SELECT member_id, member_loans, NTILE(4) OVER (ORDER BY  member_loans DESC, member_id) AS quartiles
FROM loans_per_member)
SELECT  quartiles, SUM(member_loans) AS total_loans, COUNT(*) AS members, ROUND(100.0*SUM(member_loans)/SUM(SUM(member_loans)) OVER(), 1) AS share
FROM member_quartiles
GROUP BY quartiles
ORDER BY quartiles;
-- Result: the top 25% of members make 69.3% of all loans; the bottom 25% make 2.2%.
-- Note: NTILE splits ties at the borders arbitrarily (by member_id).

-- W10: % of members who made a 2nd loan within 30 days of their 1st, by membership type.
-- Why: an early-retention / activation metric. Members who come back quickly tend to stay.
WITH numbered_loans AS(
SELECT member.membership_type AS membership_type,  member.id AS member_id, loan.loan_date AS loan_date, ROW_NUMBER() OVER(PARTITION BY member.id ORDER BY loan.loan_date, loan.id) AS loan_number
FROM library_member AS member
JOIN library_loan AS loan
ON member.id=loan.member_id),
	diff_date AS(
SELECT first_loan.membership_type, first_loan.member_id, CAST(JULIANDAY(second_loan.loan_date)-JULIANDAY(first_loan.loan_date) AS integer) AS day_diff
FROM numbered_loans AS first_loan
LEFT JOIN numbered_loans AS second_loan
ON first_loan.member_id=second_loan.member_id
AND second_loan.loan_number=2
WHERE first_loan.loan_number=1
AND first_loan.loan_date <= date('now', 'localtime', '-30 days'))
SELECT membership_type,COUNT(*) AS members, ROUND(100.0*SUM(CASE WHEN day_diff<=30 THEN 1  ELSE 0 END)/COUNT(*), 1) AS returned_share
FROM diff_date
GROUP BY membership_type
ORDER BY returned_share;
-- Definition: denominator = members whose 1st loan was at least 30 days ago, (newer members haven't had the full 30 days yet: censored data).
--   Members with only one loan count as "no". Members with no loans are excluded.
-- Result: student 70.6% (109 members), standard 58% (176), premium 75.9% (58).
-- Note: "loan_number = 2" is in ON, not WHERE, so one-loan members are kept.
