-- P2: Monthly cohort retention
-- Database: kutubxona_v2.sqlite
-- Why: shows how long members keep borrowing after joining, and whether newer cohorts behave differently
-- Definition: cohort = join month (joined_date). mN = % of the cohort with >= 1 loan N months after the join month.
WITH members AS(
SELECT id, STRFTIME('%Y-%m', joined_date)  AS cohort, 
		 CAST(STRFTIME('%Y', joined_date) AS integer)*12+CAST(STRFTIME('%m', joined_date) AS integer) AS join_idx
FROM library_member),
	activity AS(
SELECT DISTINCT member_id, CAST(STRFTIME('%Y', loan_date) AS integer)*12+CAST(STRFTIME('%m', loan_date) AS integer) AS loan_idx
FROM library_loan),
	cohort_size AS(
SELECT  cohort, COUNT(id) AS cohort_size
FROM members
GROUP BY cohort),
	retention AS(
SELECT  cohort, loan_idx-join_idx AS month_since_join, COUNT(id) AS active_members
FROM members
JOIN activity
ON members.id=activity.member_id
GROUP BY cohort, month_since_join)
SELECT c.cohort, cohort_size, 
		 MAX(CASE WHEN month_since_join=0 THEN ROUND(100.0*active_members/cohort_size, 1)  END) AS m0,
		 MAX(CASE WHEN month_since_join=1 THEN ROUND(100.0*active_members/cohort_size, 1) END)AS m1,
		 MAX(CASE WHEN month_since_join=2 THEN ROUND(100.0*active_members/cohort_size, 1) END)AS m2,
		 MAX(CASE WHEN month_since_join=3 THEN ROUND(100.0*active_members/cohort_size, 1) END)AS m3,
		 MAX(CASE WHEN month_since_join=6 THEN ROUND(100.0*active_members/cohort_size, 1) END)AS m6,
		 MAX(CASE WHEN month_since_join=12 THEN ROUND(100.0*active_members/cohort_size, 1) END)AS m12
FROM cohort_size AS c
JOIN retention AS r
ON c.cohort=r.cohort
GROUP BY c.cohort, c.cohort_size
ORDER BY c.cohort;
-- Result (averages weighted by cohort size, incomplete cells excluded):
--         m0 60%, m1 62%, m2 52%, m3 50%, m6 42%, m12 26%.
--         m1 is often higher than m0: many members take their first book the month after joining (activation gap).
--         From m3 on, older and newer cohorts retain about the same (~50% at m3, ~42% at m6).
--         m0 fell from 69% (cohorts 2024-12..2025-06) to 56% (2026 cohorts): newer members start borrowing later.
-- Check: 25 cohorts, sizes add up to 400; no negative months; all % between 0 and 100.
-- Note: empty cells (NULL) = months that haven't happened yet. Cells that fall in 2026-11 are incomplete
--       (2026-08 m3, 2026-09 m2, 2026-10 m1, 2026-11 m0) and look too low.
--       Cohorts are small (7-30 members), so single cells jump; compare group averages, not single cells.