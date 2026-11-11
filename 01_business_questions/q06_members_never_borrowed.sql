--Q6: Which members have never borrowed a book?
--Why: marketing wants to send them a "come back" message.
SELECT member.first_name ||' ' || member.last_name AS full_name, member.email, loan.id
FROM library_member AS member
LEFT JOIN library_loan AS loan
ON member.id=loan.member_id
WHERE loan.id IS NULL;
-- Result: 0 rows. Verified: LEFT JOIN without WHERE shows every member has >= 1 loan.
-- Re-check on Kutubxona v2.
 