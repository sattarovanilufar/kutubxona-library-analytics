-- Q9b: Which members owe more than 5,000 so'm in unpaid fines?
-- Why: the librarian wants a list of members to remind about their debt.\
SELECT member.first_name || ' ' || member.last_name AS name, SUM(fine.amount) AS total_unpaid, COUNT(*) AS total_unpaid
FROM library_fine AS fine
JOIN library_loan AS loan
ON fine.loan_id=loan.id
JOIN library_member AS member
ON loan.member_id=member.id
WHERE paid=0 
GROUP BY member.id
HAVING SUM(fine.amount)>5000
ORDER BY total_unpaid DESC;
-- Result (run on 2026-10-16): 4 members; the biggest debt is 16,000so'm (1 fine).
-- Note: WHERE removes paid fines BEFORE grouping; HAVING keeps big totals AFTER grouping.
-- Note: the path is fine -> loan -> member, because a fine has no member_id.