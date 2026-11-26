-- P3: Reservation funnel (placed -> fulfilled -> borrowed within 30 days)
-- Database: kutubxona_v2.sqlite (as of 2026-11-10).
-- Why: shows where reservations are lost, so the library knows which step to improve
-- Definition: placed = finished reservations (status fulfilled or cancelled; 'waiting' excluded, not finished yet).
--             borrowed = same member borrowed the same book within 30 days after the reservation date.
WITH as_of AS (
	SELECT MAX(loan_date) AS d 
	FROM library_loan),
	finished_reservations AS (
    SELECT id, DATE(reserved_at) AS reserved, status, book_id, member_id
    FROM library_reservation
    CROSS JOIN as_of
    WHERE (status='fulfilled' OR status= 'cancelled')
      AND DATE(reserved_at) <= DATE(d, '-30 days')),
	funnel_steps AS(
SELECT r.id, r.reserved, r.status, r.book_id, r.member_id, 
		 CASE WHEN status = 'fulfilled'
      AND EXISTS (SELECT 1 FROM library_loan l
                  WHERE l.member_id = r.member_id
                    AND l.book_id   = r.book_id
                    AND l.loan_date BETWEEN r.reserved AND DATE(r.reserved, '+30 days'))
     THEN 1 ELSE 0 END AS borrowed
FROM finished_reservations AS r)
SELECT COUNT(*) AS placed, 
		 SUM(CASE WHEN status='fulfilled' THEN 1 ELSE 0 END) AS fulfilled_num, 
		 SUM(borrowed) AS borrowed_num,
		 ROUND(100.0*SUM(CASE WHEN status='fulfilled' THEN 1 ELSE 0 END)/COUNT(*), 1) AS pct_fulfilled, 
		 ROUND(100.0*SUM(borrowed)/SUM(CASE WHEN status='fulfilled' THEN 1 ELSE 0 END), 1) AS pct_borrowed
FROM funnel_steps;
-- Result (v2, as of 2026-11-10): placed 207 -> fulfilled 162 (78.3%) -> borrowed 132 (81.5% of fulfilled); 63.8% end to end.
--         The biggest drop is placed -> fulfilled: 45 of 207 (21.7%) are cancelled before the book is ready,
--         slightly more than members not picking up a ready book (30 of 162, 18.5%). The gap is small (~3 points).
-- Check: borrowed <= fulfilled <= placed; status counts add up (47 cancelled + 241 fulfilled + 79 waiting = 367).
-- Note: only reservations made at least 30 days before the as-of date (cutoff 2026-10-11) are included,
--       because each needs a full 30-day window to be borrowed, and the data stops on 2026-11-10.
--       Without any cutoff the funnel showed 288 -> 241 (83.7%) -> 181 (75.1%) and pointed at the wrong step:
--       recent finished reservations were almost all fulfilled, because cancellations take longer to happen.
--       With date('now') instead of the as-of date, the cutoff was wrong too (213 -> 166 -> 136).
--       reserved_at includes a time, so DATE() is used before comparing with loan_date.
--       Online reservation launched on 2026-01-07 (first reserved_at).