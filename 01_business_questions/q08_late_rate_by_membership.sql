--Q8: For each membership type: total loans, late loans, and late rate %.
-- Result (v2, as of 2026-11-10):
--   student   1,143 loans, 321 late -> 28.1%
--   standard  1,290 loans, 240 late -> 18.6%
--   premium   1,046 loans, 100 late ->  9.6%
-- Students are late almost 3x as often as premium members.
-- Check: 1,143 + 1,290 + 1,046 = 3,479 = all loans.
-- Note: on the small Django database (47 loans) premium looked almost as late as students (41.7% vs 42.9%);
--       I noted it was probably luck. With 3,479 loans the real order is clear: small samples mislead.
--       Late = returned after due_date, or not returned and due_date before the as-of date (2026-11-10).
--       The 128 active loans count as "not late", but some may still become late (their outcome is unknown).
WITH as_of AS (
	SELECT MAX(loan_date) AS d 
	FROM library_loan)
SELECT  member.membership_type, COUNT(loan.id) AS total_loans, SUM(CASE WHEN loan.return_date>loan.due_date OR (loan.return_date IS NULL AND loan.due_date <d) THEN 1 ELSE 0 END ) AS late_loans, round(100.0*SUM(CASE WHEN loan.return_date>loan.due_date OR (loan.return_date IS NULL AND loan.due_date <d) THEN 1 ELSE 0 END )/COUNT(loan.id), 1) AS late_rate
FROM library_member AS member
LEFT JOIN library_loan AS loan
ON member.id=loan.member_id
CROSS JOIN as_of
GROUP BY member.membership_type
ORDER BY late_rate DESC;