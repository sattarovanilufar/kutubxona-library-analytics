-- =====================================================================
-- Week 3: Data cleaning
-- Database: kutubxona_messy.sqlite (copy of v2 with planted problems)
-- Numbering matches data_issues_log.md
-- =====================================================================

-- =========================================
-- PART 1: DATA CHECKS
-- =========================================

-- Check 1 (size): row counts of the main tables
-- Why: compare with the clean v2 database (400 members, 36 books, 3,479 loans)
-- Result: member 412 (+12), loan 3,519 (+40), book 36 (same), fine 636
-- Note: +12 members and +40 loans suggested duplicates; confirmed in issues 4 and 7
SELECT
    (SELECT COUNT(*) FROM library_member) AS row_count_member,
    (SELECT COUNT(*) FROM library_loan)   AS row_count_loan,
    (SELECT COUNT(*) FROM library_book)   AS row_count_book,
    (SELECT COUNT(*) FROM library_fine)   AS row_count_fine;


-- Issue 1 (check 2, categories): membership_type written in different ways
-- Why: GROUP BY membership_type would split one type into several groups
-- Result: 12 distinct values instead of 3; 76 of 412 rows (18%) are not exactly standard/student/premium
-- Note: problems are letter case (STANDARD), spaces (' student'), and the typo 'standart'
SELECT '[' || membership_type || ']' AS type_in_brackets, COUNT(*) AS n
FROM library_member
GROUP BY membership_type
ORDER BY n DESC;

SELECT COUNT(*) AS bad_type_rows
FROM library_member
WHERE membership_type NOT IN ('standard', 'student', 'premium');


-- Issue 2 (check 2, categories): language written in different ways
-- Why: language reports would show 8 languages instead of 2
-- Result: 19 of 36 books (53%) are not exactly 'Uzbek' or 'English'
-- Note: variants include ENG, english, ' Uzbek', O'zbek; the brackets make spaces visible
SELECT '[' || language || ']' AS language_in_brackets, COUNT(*) AS n
FROM library_book
GROUP BY language
ORDER BY n DESC;

SELECT COUNT(*) AS bad_language_rows
FROM library_book
WHERE language NOT IN ('Uzbek', 'English');


-- Issue 3 (check 3, missing): members with no email
-- Why: email is how we find duplicate people (issue 4)
-- Result: 12 members
-- Note: TRIM(email) = '' also catches emails that contain only spaces
SELECT COUNT(*) AS missing_email
FROM library_member
WHERE email IS NULL OR TRIM(email) = '';


-- Issue 4 (check 5, duplicates): same person registered twice
-- Why: duplicate people inflate member counts and split one person's loans
-- Result: 12 emails appear 2 times each (matches the +12 from check 1)
-- Note: emails are compared after LOWER + TRIM; members with no email are excluded
SELECT LOWER(TRIM(email)) AS email_clean, COUNT(*) AS times
FROM library_member
WHERE email IS NOT NULL AND TRIM(email) <> ''
GROUP BY email_clean
HAVING COUNT(*) > 1;


-- Issue 5 (check 4, format): joined_date not in YYYY-MM-DD
-- Why: date filters and strftime() give wrong results or NULL for these rows
-- Result: 29 of 412 members (7%); 0 NULL dates
-- Note: the IS NULL part was added to check for missing dates; the count stayed 29
SELECT COUNT(*) AS not_formatted
FROM library_member
WHERE joined_date IS NULL
   OR joined_date NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';


-- Issue 6 (check 4, format): loan_date in YYYY/MM/DD instead of YYYY-MM-DD
-- Why: '2026/03/05' > '2026-12-31' is TRUE as text, so date comparisons break
-- Result: 25 loans
-- Note: the order is already correct; only '/' needs to become '-'
SELECT COUNT(*) AS not_formatted
FROM library_loan
WHERE loan_date NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';


-- Issue 7 (check 5, duplicates): same loan entered twice
-- Why: duplicates inflate loan counts and every metric built on them
-- Result: 40 pairs, so 40 extra rows (matches the +40 from check 1)
-- Note: NULL return_dates are grouped together, so unreturned duplicates are found too.
--       Fix date formats first, otherwise '2025/03/05' and '2025-03-05' look different.
SELECT COUNT(*) AS times
FROM library_loan
GROUP BY loan_date, book_id, member_id, due_date, return_date
HAVING COUNT(*) > 1;


-- Issue 8 (check 6, logic): returned before borrowed
-- Why: impossible values; they would give negative loan durations
-- Result: 12 loans (0.3% of 3,519)
-- Note: REPLACE fixes the '/' dates before comparing; NULL return_dates are not counted
SELECT COUNT(*) AS returned_before_borrowed
FROM library_loan
WHERE REPLACE(loan_date, '/', '-') > return_date;


-- Issues 9 and 10 (check 6, logic): impossible fine values
-- Why: negative amounts reduce fine totals; paid fines with no date break "days to pay" metrics
-- Result: 4 fines with amount <= 0; 7 fines marked paid with no paid_date
-- Note: amount must be > 0 in the real Django model; the messy copy has no constraints
SELECT SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END)                   AS non_positive_amount,
       SUM(CASE WHEN paid = 1 AND paid_date IS NULL THEN 1 ELSE 0 END) AS paid_without_date
FROM library_fine;


-- Issue 11 (check 6, logic): orphan loans (member_id not found in library_member)
-- Why: these loans can't be linked to a member, membership type or cohort
-- Result: 6 loans
-- Note: WHERE ... IS NULL after a LEFT JOIN = "no match found" (anti-join).
--       Django's FOREIGN KEY prevents this; exports and spreadsheets don't.
SELECT loan.id, loan.member_id
FROM library_loan AS loan
LEFT JOIN library_member AS member ON member.id = loan.member_id
WHERE member.id IS NULL;
