-- Q9a: How much in fines was issued, paid, and unpaid?
-- Why: the manager wants to know how much money the library is still owed.
-- Result (v2): total 9,744,000 so'm, paid 6,903,000 so'm, unpaid 2,841,000 so'm.
-- Insight: about 29% of fine money is still unpaid.
-- Check: paid + unpaid = total, so every fine is in exactly one group.
-- Note: 'paid' is stored as 1/0 (true/false) in SQLite.
SELECT SUM(amount) AS total_amount,
		 SUM(CASE WHEN paid=1 THEN amount ELSE 0 END) AS amount_paid, 
		 SUM(CASE WHEN paid=0 THEN amount ELSE 0 END) AS amount_unpaid
FROM library_fine;
