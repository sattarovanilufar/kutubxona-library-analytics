-- Q9a: How much in fines was issued, paid, and unpaid?
-- Why: the manager wants to know how much money the library is still owed.
SELECT SUM(amount) AS total_amount,
		 SUM(CASE WHEN paid=1 THEN amount ELSE 0 END) AS amount_paid, 
		 SUM(CASE WHEN paid=0 THEN amount ELSE 0 END) AS amount_unpaid
FROM library_fine;
-- Result (run on 2026-10-16): total 100,004.83 so'm, paid 46,004.83 so'm, unpaid 54,000 so'm.
-- Insight: about 54%(53.99) of fine money is still unpaid.
-- Check: paid + unpaid = total, so every fine is in exactly one group.
-- Note: 'paid' is stored as 1/0 (true/false) in SQLite.