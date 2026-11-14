# Data issues log: kutubxona_messy.sqlite
| # | Table | Column | Problem | Rows affected | How found (check #) | Decision |
|---|---|---|---|---|---|---|
| 1 | library_member | membership_type | Same type written in different ways (STANDARD, ' student', typo 'standart') | 76 | Check 2 (categories) | Fix later: LOWER(TRIM(...)), 'standart' → 'standard' |
| 2 | library_book | language | Same language written in different ways (ENG, english, ' Uzbek', O'zbek) | 19 | Check 2 (categories) | Fix later: map all variants to 'Uzbek' or 'English' |
| 3 | library_member | email | Missing email (NULL, empty, or only spaces) | 12 | Check 3 (missing) | Keep these members; they can't be deduplicated by email |
| 4 | library_member | email | Same person registered twice (same email after LOWER + TRIM)  | 12 | Check 5 (duplicates) | In member_clean keep the oldest id, leave the newer copy out |
| 5 | library_member | joined_date | Dates in DD.MM.YYYY format instead of YYYY-MM-DD | 29 | Check 4 (format) | Fix in member_clean: rearrange to YYYY-MM-DD |
| 6 | library_loan | loan_date | Dates in YYYY/MM/DD format instead of YYYY-MM-DD | 25 | Check 4 (format) | Fix in loan_clean: replace '/' with '-', REPLACE(loan_date, '/', '-') |
| 7 | library_loan | all columns except id | Same loan entered twice | 40 | Check 5 (duplicates) | In loan_clean keep the oldest id, leave the newer copy out |
| 8 | library_loan | return_date | Returned before borrowed (return_date < loan_date) | 12 | Check 6 (logic) | Remove from loan_clean (12 of 3519 = 0.3%, too small to change results) |
| 9 | library_fine | amount | Negative fine amount | 4 | Check 6 (logic) | Leave out of fine totals (4 of 636); likely a sign error, but we can't be sure |
| 10 | library_fine | paid_date | Marked paid (paid = 1) but no paid_date | 7 | Check 6 (logic) | Keep as paid; treat paid_date as unknown, leave out of "days to pay" metrics |
| 11 | library_loan | member_id | Orphan loans: member_id doesn't exist in library_member | 6 | Check 6 (logic) | Remove from loan_clean; we can't know who borrowed the book |



Note: run duplicate checks AFTER fixing date formats, otherwise some duplicates are missed.

