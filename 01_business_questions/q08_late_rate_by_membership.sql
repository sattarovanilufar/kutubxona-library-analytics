--Q8: For each membership type: total loans, late loans, and late rate %.

SELECT  member.membership_type, COUNT(loan.id) AS total_loans, SUM(CASE WHEN loan.return_date>loan.due_date OR (loan.return_date IS NULL AND loan.due_date <DATE('now', 'localtime')) THEN 1 ELSE 0 END ) AS late_loans, round(100.0*SUM(CASE WHEN loan.return_date>loan.due_date OR (loan.return_date IS NULL AND loan.due_date <DATE('now', 'localtime')) THEN 1 ELSE 0 END )/COUNT(loan.id), 1) AS late_rate
FROM library_member AS member
LEFT JOIN library_loan AS loan
ON member.id=loan.member_id
GROUP BY member.membership_type
ORDER BY late_rate DESC;

-- Result (run on 2026-10-16):
--   student   14 loans, 6 late -> 42.9%
--   premium   12 loans, 5 late -> 41.7%
--   standard  21 loans, 7 late -> 33.3%
-- Students and premium members are late most often, standard members least.
-- But the groups are very small: one loan changes the rate by about 5-8%.
-- Student vs premium differ by only 1.2%, less than one loan, so this is luck.
-- Student vs standard differ by 9.6%, only 1-2 loans, so it may be luck too.
-- I will re-check this on Kutubxona v2 (~3,000 loans) before drawing a conclusion.
-- Note: 47 loans in total (45 from the seed + 2 I added in the admin).