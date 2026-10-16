# Kutubxona Library Analytics

SQL analysis of a library management database (my Django project "Kutubxona").

## Questions answered (Week 1)
1. Books per category
2. Loan status: returned / active / overdue
3. Overdue call list (days late)
4. Top 5 most borrowed books
5. Loans per month (trend)
6. Members who never borrowed
7. Books and loans per author
8. Late rate by membership type
9. Fines: paid vs unpaid, members who owe the most
10. Average days a book is kept, per category

## Tools
SQLite, HeidiSQL  for SQLite

## Files
Each question is in its own file, with the business question, the result and notes as comments:
`q01_books_per_category.sql` … `q10_avg_days_kept.sql`

*Work in progress: window functions, cohorts and Python charts coming next.*