--Q6: Which members have never borrowed a book?
--Why: marketing wants to send them a "first book" welcome message.
-- Result (v2): 35 of 400 members (9%) have never borrowed a book.
-- Check: same as P1 (400 members - 365 distinct borrowers = 35).
-- Note: joined_date shows who is really inactive and who joined too recently to have borrowed yet.
--       These members need a "how to borrow your first book" welcome message (see Key finding 4).
SELECT member.id, member.first_name ||' ' || member.last_name AS full_name, member.email,  member.joined_date
FROM library_member AS member
LEFT JOIN library_loan AS loan
ON member.id=loan.member_id
WHERE loan.id IS NULL
ORDER BY member.joined_date;