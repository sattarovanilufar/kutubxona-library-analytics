-- P3: Reservation funnel (placed -> fulfilled -> borrowed within 30 days)
-- Database: kutubxona_v2.sqlite (run on 2026-11-16)
-- Why: shows where reservations are lost, so the library knows which step to improve
-- Definition: placed = finished reservations (status fulfilled or cancelled; 'waiting' excluded, not finished yet).
--             borrowed = same member borrowed the same book within 30 days after the reservation date.
WITH finished_reservations AS (
    SELECT id, DATE(reserved_at) AS reserved, status, book_id, member_id
    FROM library_reservation
    WHERE (status='fulfilled' OR status= 'cancelled')
      AND DATE(reserved_at) <= DATE('now', '-30 days')),
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
-- Result: placed 213 -> fulfilled 166 (77.9%) -> borrowed 136 (81.9% of fulfilled); 63.8% end to end.
--         The biggest drop is placed -> fulfilled: 47 of 213 (22%) are cancelled before the book is ready.
-- Check: status counts add up (47 cancelled + 241 fulfilled + 79 waiting = 367); borrowed <= fulfilled.
-- Note: reservations from the last 30 days are excluded (they haven't had the full 30-day window).
--       Without this, the funnel showed 288 -> 241 (83.7%) -> 181 (75.1%) and pointed at the wrong step.
--       All 47 cancellations are older than 30 days, so recent finished reservations were biased toward fulfilled.
--       reserved_at includes a time, so DATE() is used before comparing with loan_date.
--       Online reservation launched on 2026-01-07 (first reserved_at).