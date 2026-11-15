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


-- Issue 12 (format): first names with extra spaces
-- Why: 'Ali ' and 'Ali' look the same but don't match in joins or GROUP BY
-- Result: 42 of 412 members (10%)
-- Note: if TRIM changes the value, it had spaces
SELECT COUNT(*) AS bad_names
FROM library_member
WHERE TRIM(first_name) <> first_name;


-- Issue 13 (format): last names in ALL CAPITALS
-- Why: reports and name searches show the same family name in two styles
-- Result: 20 of 412 members (5%)
-- Note: SQLite '=' is case-sensitive, so 'Karimov' <> 'KARIMOV'
SELECT COUNT(*) AS capital_last_names
FROM library_member
WHERE UPPER(last_name) = last_name;


-- Issue 14 (format): phone numbers in a different format
-- Why: the same phone written two ways can't be matched or used for SMS reminders
-- Result: 73 of 412 members (18%)
-- Note: correct format starts with +998
SELECT COUNT(*) AS different_format
FROM library_member
WHERE phone NOT LIKE '+998%';

-- =========================================
-- PART 2: CLEAN VIEWS
-- =========================================

-- View 1: member_clean
-- Why: one clean row per real person; fixes issues 1, 3, 4, 5, 12, 13, 14
-- Result: 412 raw rows -> 400 clean rows (12 duplicates removed, 12 members without email kept)
-- Note: duplicates = same email after LOWER + TRIM; the oldest id is kept.
--       Members without email get a unique key ('no-email-' || id), so they are not merged.
--       Known limit: last names become "Capital + small letters" (Abdul-Karimov -> Abdul-karimov).
--       Phone target format: +998901234567 (no spaces).
DROP VIEW IF EXISTS member_clean;
CREATE VIEW member_clean AS
WITH fixed AS (
    SELECT id,
           TRIM(first_name) AS first_name,
           UPPER(SUBSTR(TRIM(last_name), 1, 1)) || LOWER(SUBSTR(TRIM(last_name), 2)) AS last_name,
           NULLIF(LOWER(TRIM(email)), '') AS email,
           CASE WHEN LOWER(TRIM(membership_type)) = 'standart' THEN 'standard'
                ELSE LOWER(TRIM(membership_type)) END AS membership_type,
           CASE WHEN joined_date LIKE '__.__.____'
                THEN SUBSTR(joined_date, 7, 4) || '-' || SUBSTR(joined_date, 4, 2) || '-' || SUBSTR(joined_date, 1, 2)
                ELSE joined_date END AS joined_date,
           CASE WHEN phone LIKE '8%' THEN '+998' || SUBSTR(REPLACE(phone, ' ', ''), 2)
                ELSE REPLACE(phone, ' ', '') END AS phone,
           is_active
    FROM library_member
),
ranked AS (
    SELECT id, first_name, last_name, email, membership_type, joined_date, phone, is_active,
           ROW_NUMBER() OVER (PARTITION BY COALESCE(email, 'no-email-' || id) ORDER BY id) AS rn
    FROM fixed
)
SELECT id, first_name, last_name, email, membership_type, joined_date, phone, is_active
FROM ranked
WHERE rn = 1;

-- Checks on member_clean (all passed)
-- Result: 400 rows; 3 membership types; 0 bad joined_date; 0 capital last names
SELECT COUNT(*) AS clean_rows FROM member_clean;
SELECT membership_type, COUNT(*) FROM member_clean GROUP BY membership_type;
SELECT COUNT(*) AS bad_dates FROM member_clean
WHERE joined_date NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';
SELECT COUNT(*) AS capital_last_names FROM member_clean WHERE UPPER(last_name) = last_name;


-- View 2: loan_clean
-- Why: one clean row per real loan; fixes issues 6, 7, 8, 11
-- Result: 3,519 raw rows -> 3,461 clean rows (-40 duplicates, -12 returned before borrowed, -6 orphans)
-- Note: loan_date is fixed BEFORE removing duplicates, otherwise '2025/03/05' and '2025-03-05' look different.
--       Unreturned loans (return_date IS NULL) are kept; same-day returns (>=) are valid.
--       Joined with raw library_member (not member_clean), so no loan is hidden.
--       Checked: 0 loans belong to the 12 duplicate member ids removed in member_clean.
--       AND runs before OR, so the return condition is in brackets.
DROP VIEW IF EXISTS loan_clean;
CREATE VIEW loan_clean AS
WITH fixed AS (
    SELECT id, REPLACE(loan_date, '/', '-') AS loan_date, due_date, return_date, book_id, member_id
    FROM library_loan
),
ranked AS (
    SELECT id, loan_date, due_date, return_date, book_id, member_id,
           ROW_NUMBER() OVER (PARTITION BY loan_date, due_date, return_date, book_id, member_id
                              ORDER BY id) AS rn
    FROM fixed
)
SELECT ranked.id, loan_date, due_date, return_date, book_id, member_id
FROM ranked
JOIN library_member AS member ON ranked.member_id = member.id
WHERE rn = 1
  AND (return_date >= loan_date OR return_date IS NULL);

-- Checks on loan_clean (all passed)
-- Result: 3,461 rows; 0 bad loan_date; 0 duplicate groups; 0 returned before borrowed; 0 orphans
SELECT COUNT(*) AS clean_rows FROM loan_clean;