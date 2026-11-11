"""
make_kutubxona_v2.py  -  builds two practice databases for analysis.

    kutubxona_v2.sqlite     clean, bigger, realistic (~300 members, ~2 years)
    kutubxona_messy.sqlite  the same data with typical real-world problems
                            (duplicates, bad formats, impossible values...)

It does NOT need Django and does NOT touch your Django db.sqlite3.
Table and column names are the same as in your Django project, so every
query you write for Kutubxona works on these files too.

Run (in PowerShell, from the folder that contains this file):
    py make_kutubxona_v2.py
Optional: choose an output folder
    py make_kutubxona_v2.py D:\\projects\\1\\data

Only the Python standard library is used. Same output every run
(fixed random seed), but dates are relative to TODAY.
"""
import math
import random
import re
import sqlite3
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

SEED = 2026
TODAY = date.today()
START = TODAY - timedelta(days=730)            # two years of history
RESERVATION_LAUNCH = START + timedelta(days=420)  # "online reservations" feature launch
LOAN_DAYS = 14
FINE_PER_DAY = 1000
N_MEMBERS = 400

SCHEMA = """
CREATE TABLE library_category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL
);
CREATE TABLE library_publisher (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(150) NOT NULL UNIQUE,
    city VARCHAR(100) NOT NULL,
    founded_year SMALLINT NULL
);
CREATE TABLE library_author (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_year SMALLINT NULL,
    country VARCHAR(100) NOT NULL,
    bio TEXT NOT NULL
);
CREATE TABLE library_book (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(13) NOT NULL UNIQUE,
    publication_year SMALLINT NULL,
    pages INTEGER NOT NULL CHECK (pages > 0),
    language VARCHAR(50) NOT NULL,
    total_copies SMALLINT NOT NULL CHECK (total_copies >= 1),
    added_at DATETIME NOT NULL,
    category_id INTEGER NOT NULL REFERENCES library_category(id),
    publisher_id INTEGER NULL REFERENCES library_publisher(id)
);
CREATE TABLE library_book_authors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id INTEGER NOT NULL REFERENCES library_book(id),
    author_id INTEGER NOT NULL REFERENCES library_author(id),
    UNIQUE (book_id, author_id)
);
CREATE TABLE library_member (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    membership_type VARCHAR(10) NOT NULL,
    joined_date DATE NOT NULL,
    is_active BOOL NOT NULL
);
CREATE TABLE library_loan (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    book_id INTEGER NOT NULL REFERENCES library_book(id),
    member_id INTEGER NOT NULL REFERENCES library_member(id),
    CHECK (due_date >= loan_date),
    CHECK (return_date IS NULL OR return_date >= loan_date)
);
CREATE TABLE library_reservation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reserved_at DATETIME NOT NULL,
    status VARCHAR(10) NOT NULL,
    book_id INTEGER NOT NULL REFERENCES library_book(id),
    member_id INTEGER NOT NULL REFERENCES library_member(id)
);
CREATE TABLE library_fine (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    issued_date DATE NOT NULL,
    paid BOOL NOT NULL,
    paid_date DATE NULL,
    loan_id INTEGER NOT NULL UNIQUE REFERENCES library_loan(id)
);
"""

# The messy database has the same columns but NO constraints at all,
# exactly like a careless spreadsheet export.
MESSY_SCHEMA = SCHEMA
for pattern, repl in [
    (r",\n\s*CHECK \([^\n]*\)", ""),          # table-level CHECK lines
    (r",\n\s*UNIQUE \([^)]*\)", ""),          # UNIQUE (book_id, author_id)
    (r" CHECK \([^)]*\)", ""),                # inline CHECK (...)
    (r" NOT NULL", ""),
    (r" UNIQUE", ""),
]:
    MESSY_SCHEMA = re.sub(pattern, repl, MESSY_SCHEMA)

CATEGORIES = [
    ("Novel", "Long-form fiction"),
    ("Poetry", "Poems and verse"),
    ("History & Society", "History, philosophy and society"),
    ("Popular Science", "Science explained for everyone"),
    ("Children", "Books for young readers"),
    ("World Classics", "Classic literature from around the world"),
]
PUBLISHERS = [
    ("Sharq", "Tashkent", 1990),
    ("Yangi asr avlodi", "Tashkent", 1996),
    ("G'afur G'ulom nashriyoti", "Tashkent", 1957),
    ("Penguin Books", "London", 1935),
    ("Bantam Books", "New York", 1945),
]
AUTHORS = {
    "qodiriy": ("Abdulla", "Qodiriy", 1894, "Uzbekistan"),
    "cholpon": ("Abdulhamid", "Cho'lpon", 1897, "Uzbekistan"),
    "navoiy": ("Alisher", "Navoiy", 1441, "Uzbekistan"),
    "hoshimov": ("O'tkir", "Hoshimov", 1941, "Uzbekistan"),
    "toxtaboyev": ("Xudoyberdi", "To'xtaboyev", 1932, "Uzbekistan"),
    "vohidov": ("Erkin", "Vohidov", 1936, "Uzbekistan"),
    "gulom": ("G'afur", "G'ulom", 1903, "Uzbekistan"),
    "qodirov": ("Pirimqul", "Qodirov", 1928, "Uzbekistan"),
    "yoqubov": ("Odil", "Yoqubov", 1926, "Uzbekistan"),
    "bobur": ("Zahiriddin Muhammad", "Bobur", 1483, "Uzbekistan"),
    "aytmatov": ("Chingiz", "Aytmatov", 1928, "Kyrgyzstan"),
    "orwell": ("George", "Orwell", 1903, "United Kingdom"),
    "harari": ("Yuval Noah", "Harari", 1976, "Israel"),
    "hawking": ("Stephen", "Hawking", 1942, "United Kingdom"),
    "mlodinow": ("Leonard", "Mlodinow", 1954, "United States"),
    "exupery": ("Antoine", "de Saint-Exupery", 1900, "France"),
    "coelho": ("Paulo", "Coelho", 1947, "Brazil"),
    "kahneman": ("Daniel", "Kahneman", 1934, "Israel"),
    "levitt": ("Steven", "Levitt", 1967, "United States"),
    "dubner": ("Stephen", "Dubner", 1963, "United States"),
    "rosling": ("Hans", "Rosling", 1948, "Sweden"),
    "dostoevsky": ("Fyodor", "Dostoevsky", 1821, "Russia"),
    "tolstoy": ("Leo", "Tolstoy", 1828, "Russia"),
    "hemingway": ("Ernest", "Hemingway", 1899, "United States"),
}
# title, authors, category, publisher, year, pages, language, copies, popularity
BOOKS = [
    ("O'tkan kunlar", ["qodiriy"], "Novel", "Sharq", 1926, 400, "Uzbek", 5, 10),
    ("Mehrobdan chayon", ["qodiriy"], "Novel", "Sharq", 1929, 320, "Uzbek", 3, 6),
    ("Kecha va kunduz", ["cholpon"], "Novel", "Sharq", 1936, 350, "Uzbek", 3, 5),
    ("Uyg'onish", ["cholpon"], "Poetry", None, 1922, 150, "Uzbek", 1, 2),
    ("Xamsa", ["navoiy"], "Poetry", "Sharq", 1485, 900, "Uzbek", 2, 3),
    ("Mahbub ul-qulub", ["navoiy"], "History & Society", None, 1500, 210, "Uzbek", 1, 2),
    ("Dunyoning ishlari", ["hoshimov"], "Novel", "Yangi asr avlodi", 1982, 300, "Uzbek", 4, 8),
    ("Ikki eshik orasi", ["hoshimov"], "Novel", "Yangi asr avlodi", 1986, 480, "Uzbek", 3, 6),
    ("Bahor qaytmaydi", ["hoshimov"], "Novel", "Yangi asr avlodi", 1970, 260, "Uzbek", 2, 3),
    ("Sariq devni minib", ["toxtaboyev"], "Children", "Yangi asr avlodi", 1968, 220, "Uzbek", 4, 7),
    ("Sariq devning o'limi", ["toxtaboyev"], "Children", "Yangi asr avlodi", 1973, 240, "Uzbek", 2, 4),
    ("Ruhlar isyoni", ["vohidov"], "Poetry", "Sharq", 1980, 180, "Uzbek", 1, 2),
    ("Shum bola", ["gulom"], "Children", "G'afur G'ulom nashriyoti", 1936, 180, "Uzbek", 4, 8),
    ("Yulduzli tunlar", ["qodirov"], "Novel", "G'afur G'ulom nashriyoti", 1979, 520, "Uzbek", 3, 6),
    ("Ulug'bek xazinasi", ["yoqubov"], "Novel", "G'afur G'ulom nashriyoti", 1973, 380, "Uzbek", 2, 4),
    ("Boburnoma", ["bobur"], "History & Society", "Sharq", 1530, 560, "Uzbek", 2, 3),
    ("Jamila", ["aytmatov"], "World Classics", "Sharq", 1958, 120, "Uzbek", 3, 5),
    ("Asrni qaritgan kun", ["aytmatov"], "World Classics", "Sharq", 1980, 450, "Uzbek", 2, 3),
    ("Oq kema", ["aytmatov"], "World Classics", "Sharq", 1970, 200, "Uzbek", 2, 3),
    ("1984", ["orwell"], "World Classics", "Penguin Books", 1949, 328, "English", 3, 7),
    ("Animal Farm", ["orwell"], "World Classics", "Penguin Books", 1945, 112, "English", 2, 5),
    ("Sapiens", ["harari"], "History & Society", "Penguin Books", 2011, 498, "English", 3, 9),
    ("Homo Deus", ["harari"], "History & Society", "Penguin Books", 2015, 450, "English", 2, 4),
    ("21 Lessons for the 21st Century", ["harari"], "History & Society", "Penguin Books", 2018, 372, "English", 1, 3),
    ("A Brief History of Time", ["hawking"], "Popular Science", "Bantam Books", 1988, 256, "English", 2, 4),
    ("Black Holes and Baby Universes", ["hawking"], "Popular Science", "Bantam Books", 1993, 200, "English", 1, 1),
    ("The Grand Design", ["hawking", "mlodinow"], "Popular Science", "Bantam Books", 2010, 208, "English", 1, 2),
    ("The Little Prince", ["exupery"], "Children", "Penguin Books", 1943, 96, "English", 3, 6),
    ("The Alchemist", ["coelho"], "World Classics", "Penguin Books", 1988, 208, "English", 3, 8),
    ("Thinking, Fast and Slow", ["kahneman"], "Popular Science", "Penguin Books", 2011, 499, "English", 2, 5),
    ("Freakonomics", ["levitt", "dubner"], "Popular Science", "Penguin Books", 2005, 320, "English", 2, 4),
    ("Factfulness", ["rosling"], "Popular Science", "Penguin Books", 2018, 352, "English", 2, 4),
    ("Crime and Punishment", ["dostoevsky"], "World Classics", "Penguin Books", 1866, 671, "English", 2, 4),
    ("War and Peace", ["tolstoy"], "World Classics", "Penguin Books", 1869, 1225, "English", 1, 2),
    ("The Old Man and the Sea", ["hemingway"], "World Classics", "Penguin Books", 1952, 127, "English", 2, 4),
    ("Jinoyat va jazo", ["dostoevsky"], "World Classics", "Sharq", 1866, 640, "Uzbek", 2, 3),
]
FIRST_NAMES = [
    "Aziz", "Dilnoza", "Jasur", "Malika", "Bekzod", "Nodira", "Sardor", "Gulnora",
    "Otabek", "Shahzoda", "Rustam", "Kamola", "Javohir", "Madina", "Sherzod", "Zarina",
    "Doniyor", "Sevara", "Akmal", "Nilufar", "Bobur", "Mohira", "Ulug'bek", "Dildora",
    "Farrux", "Gulchehra", "Islom", "Lola", "Temur", "Munisa", "Shoxrux", "Feruza",
]
LAST_NAMES = [
    "Karimov", "Rahimov", "Tursunov", "Yusupov", "Aliyev", "Saidov", "Qosimov",
    "Ergashev", "Mirzayev", "Nazarov", "Hasanov", "Ismoilov", "Abdullayev", "Sobirov",
    "Xolmatov", "Raximov", "Jo'rayev", "Umarov", "Toshpulatov", "Normatov",
]
FEMALE = {"Dilnoza", "Malika", "Nodira", "Gulnora", "Shahzoda", "Kamola", "Madina",
          "Zarina", "Sevara", "Nilufar", "Mohira", "Dildora", "Gulchehra", "Lola",
          "Munisa", "Feruza"}

# loans per month for a member of each type, and monthly chance to stop coming
BEHAVIOUR = {
    "standard": {"rate": 0.8, "churn": 0.07, "late": 0.20},
    "student": {"rate": 1.3, "churn": 0.09, "late": 0.28},
    "premium": {"rate": 1.6, "churn": 0.03, "late": 0.10},
}


def poisson(rng, lam):
    """Random count with average `lam` (Knuth's method, fine for small lam)."""
    limit, k, p = math.exp(-lam), 0, 1.0
    while True:
        p *= rng.random()
        if p <= limit:
            return k
        k += 1


def month_starts(first, last):
    d = first.replace(day=1)
    while d <= last:
        yield d
        d = (d + timedelta(days=32)).replace(day=1)


def season_factor(mtype, d):
    f = 1.0
    if d.month in (6, 7, 8):          # summer holidays
        f *= 0.5 if mtype == "student" else 0.85
    if d.month in (9, 10, 11, 2, 3):  # study months
        f *= 1.2 if mtype == "student" else 1.0
    return f


def build(rng):
    data = {k: [] for k in ["category", "publisher", "author", "book", "book_authors",
                            "member", "loan", "reservation", "fine"]}
    cat_id = {}
    for i, (name, desc) in enumerate(CATEGORIES, 1):
        data["category"].append((i, name, desc))
        cat_id[name] = i
    pub_id = {}
    for i, (name, city, year) in enumerate(PUBLISHERS, 1):
        data["publisher"].append((i, name, city, year))
        pub_id[name] = i
    auth_id = {}
    for i, (key, (f, l, y, c)) in enumerate(AUTHORS.items(), 1):
        data["author"].append((i, f, l, y, c, ""))
        auth_id[key] = i

    books = []  # (id, copies, popularity)
    ba_id = 1
    for i, (title, akeys, cat, pub, year, pages, lang, copies, pop) in enumerate(BOOKS, 1):
        copies *= 2                      # v2 library owns twice as many copies
        added = datetime.combine(START - timedelta(days=rng.randint(30, 400)), datetime.min.time())
        added += timedelta(hours=rng.randint(9, 17), minutes=rng.randint(0, 59))
        data["book"].append((i, title, f"97890{i:08d}", year, pages, lang, copies,
                             added.strftime("%Y-%m-%d %H:%M:%S"), cat_id[cat],
                             pub_id[pub] if pub else None))
        for k in akeys:
            data["book_authors"].append((ba_id, i, auth_id[k]))
            ba_id += 1
        books.append((i, copies, pop))

    # ---- members: more people join recently (growth) and in September ----
    members = []
    used_emails = set()
    for mid in range(1, N_MEMBERS + 1):
        while True:
            # bias towards recent dates (the library is growing)
            offset = int(730 * rng.random() ** 0.7)
            joined = START + timedelta(days=offset)
            if joined.month == 9 or rng.random() < 0.85:
                break
        mtype = rng.choices(["standard", "student", "premium"], [50, 35, 15])[0]
        first = rng.choice(FIRST_NAMES)
        last = rng.choice(LAST_NAMES)
        if first in FEMALE and not last.endswith("a"):
            last = last + "a"
        base = f"{first}.{last}".lower().replace("'", "")
        email, n = f"{base}@example.com", 1
        while email in used_emails:
            n += 1
            email = f"{base}{n}@example.com"
        used_emails.add(email)
        phone = f"+998 9{rng.choice('01345789')} {rng.randint(100, 999)} {rng.randint(10, 99)} {rng.randint(10, 99)}"
        members.append({"id": mid, "type": mtype, "joined": joined,
                        "row": [mid, first, last, email, phone, mtype,
                                joined.isoformat(), 1]})

    # ---- demand: each member wants books month by month until they churn ----
    wants = []  # (date, member_id, book_id, late_prob)
    pop_weights = [b[2] for b in books]
    for m in members:
        b = BEHAVIOUR[m["type"]]
        personal = rng.lognormvariate(0, 0.6)       # some people read much more
        last_seen = None
        for ms in month_starts(m["joined"], TODAY):
            if ms > m["joined"] and rng.random() < b["churn"]:
                break                                # member stops coming
            n = poisson(rng, b["rate"] * personal * season_factor(m["type"], ms))
            for _ in range(n):
                month_end = (ms + timedelta(days=32)).replace(day=1) - timedelta(days=1)
                lo = max(ms, m["joined"])
                hi = min(month_end, TODAY)
                if lo > hi:
                    continue
                d = lo + timedelta(days=rng.randint(0, (hi - lo).days))
                book = rng.choices(books, pop_weights)[0][0]
                wants.append((d, m["id"], book, b["late"]))
                last_seen = d
        # members with no activity for ~6 months are marked inactive
        if last_seen is None or (TODAY - last_seen).days > 180:
            if (TODAY - m["joined"]).days > 180:
                m["row"][7] = 0

    wants.sort()
    copies = {b[0]: b[1] for b in books}
    out = {b[0]: [] for b in books}   # list of return dates (None = not returned)
    loan_id = res_id = fine_id = 0

    def free_copy(book, d):
        busy = [r for r in out[book] if r is None or r > d]
        out[book] = busy
        return len(busy) < copies[book]

    def next_free(book, d):
        dates = sorted(r for r in out[book] if r is not None and r > d)
        return dates[0] if dates and len(out[book]) >= copies[book] else None

    def make_loan(d, member, book, late_p):
        nonlocal loan_id, fine_id
        loan_id += 1
        due = d + timedelta(days=LOAN_DAYS)
        if rng.random() < late_p:
            ret = due + timedelta(days=rng.randint(1, 30))
        else:
            ret = d + timedelta(days=rng.randint(2, LOAN_DAYS))
        ret_value = ret if ret <= TODAY else None
        data["loan"].append((loan_id, d.isoformat(), due.isoformat(),
                             ret_value.isoformat() if ret_value else None, book, member))
        out[book].append(ret_value)
        if ret_value and ret_value > due:
            fine_id += 1
            days_late = (ret_value - due).days
            paid = rng.random() < 0.7
            paid_date = min(ret_value + timedelta(days=rng.randint(0, 20)), TODAY) if paid else None
            data["fine"].append((fine_id, f"{FINE_PER_DAY * days_late:.2f}", ret_value.isoformat(),
                                 1 if paid else 0, paid_date.isoformat() if paid_date else None, loan_id))

    for d, member, book, late_p in wants:
        if free_copy(book, d):
            make_loan(d, member, book, late_p)
            continue
        # No copy available. Before the launch, the reader just leaves (lost demand).
        if d < RESERVATION_LAUNCH or rng.random() > 0.75:
            continue
        res_id += 1
        reserved_at = datetime.combine(d, datetime.min.time()) + timedelta(
            hours=rng.randint(8, 21), minutes=rng.randint(0, 59))
        free_on = next_free(book, d)
        if free_on is None or (free_on - d).days > 21 or rng.random() < 0.2:
            status = "waiting" if (TODAY - d).days <= 21 else "cancelled"
        elif free_on > TODAY:
            status = "waiting"
        else:
            status = "fulfilled"
            pickup = free_on + timedelta(days=rng.randint(0, 3))
            if pickup <= TODAY and rng.random() < 0.85 and free_copy(book, pickup):
                make_loan(pickup, member, book, late_p)
        data["reservation"].append((res_id, reserved_at.strftime("%Y-%m-%d %H:%M:%S"),
                                    status, book, member))

    data["member"] = [tuple(m["row"]) for m in members]
    data["loan"].sort(key=lambda r: (r[1], r[0]))
    return data


INSERTS = {
    "category": "INSERT INTO library_category VALUES (?,?,?)",
    "publisher": "INSERT INTO library_publisher VALUES (?,?,?,?)",
    "author": "INSERT INTO library_author VALUES (?,?,?,?,?,?)",
    "book": "INSERT INTO library_book VALUES (?,?,?,?,?,?,?,?,?,?)",
    "book_authors": "INSERT INTO library_book_authors VALUES (?,?,?)",
    "member": "INSERT INTO library_member VALUES (?,?,?,?,?,?,?,?)",
    "loan": "INSERT INTO library_loan VALUES (?,?,?,?,?,?)",
    "reservation": "INSERT INTO library_reservation VALUES (?,?,?,?,?)",
    "fine": "INSERT INTO library_fine VALUES (?,?,?,?,?,?)",
}


def write_db(path, schema, data):
    if path.exists():
        path.unlink()
    con = sqlite3.connect(path)
    con.executescript(schema)
    for table, sql in INSERTS.items():
        con.executemany(sql, data[table])
    con.commit()
    con.close()


TYPE_VARIANTS = {
    "student": ["Student", "STUDENT", " student"],
    "standard": ["Standard", "STANDARD ", "standart"],
    "premium": ["Premium", "premium ", "PREMIUM"],
}


def make_messy(rng, data):
    """Copy the clean data and break it in realistic ways."""
    d = {k: [list(r) for r in v] for k, v in data.items()}

    # Books: inconsistent language labels
    for r in d["book"]:
        if r[5] == "English":
            r[5] = rng.choice(["English", "english", "ENG", "English "])
        elif rng.random() < 0.3:
            r[5] = rng.choice(["uzbek", "O'zbek", " Uzbek"])

    # Members: spaces, casing, type variants, date formats, missing emails
    next_id = max(r[0] for r in d["member"]) + 1
    dup_rows = []
    for r in d["member"]:
        x = rng.random()
        if x < 0.10:
            r[1] = r[1] + " "                       # trailing space
        elif x < 0.15:
            r[2] = r[2].upper()                     # KARIMOV
        if rng.random() < 0.15:                     # same meaning, different spelling
            r[5] = rng.choice(TYPE_VARIANTS[r[5]])
        if rng.random() < 0.07:
            y, m, dd = r[6].split("-")
            r[6] = f"{dd}.{m}.{y}"                  # 05.03.2025 instead of 2025-03-05
        if rng.random() < 0.03:
            r[3] = None                             # missing email
        if rng.random() < 0.20:
            r[4] = r[4].replace(" ", "").replace("+998", "8")
    for r in rng.sample(d["member"][:250], 12):     # same person registered twice
        if r[3]:
            dup = list(r)
            dup[0] = next_id
            next_id += 1
            dup[3] = rng.choice([r[3].upper(), " " + r[3], r[3]])
            dup_rows.append(dup)
    d["member"].extend(dup_rows)

    # Loans: exact duplicates, impossible dates, other date format, orphans
    next_loan = max(r[0] for r in d["loan"]) + 1
    extra = []
    for r in rng.sample(d["loan"], 40):
        dup = list(r)
        dup[0] = next_loan
        next_loan += 1
        extra.append(dup)
    for r in rng.sample(d["loan"], 12):
        if r[3]:
            ld = date.fromisoformat(r[1])
            r[3] = (ld - timedelta(days=rng.randint(1, 5))).isoformat()   # returned before borrowed
    for r in rng.sample(d["loan"], 25):
        r[1] = r[1].replace("-", "/")              # 2026/03/05
    for r in rng.sample(d["loan"], 6):
        r[5] = 9000 + rng.randint(1, 99)           # member that does not exist
    d["loan"].extend(extra)

    # Fines: paid without date, negative amount
    for r in rng.sample(d["fine"], min(8, len(d["fine"]))):
        if r[3] == 1:
            r[4] = None
    for r in rng.sample(d["fine"], min(4, len(d["fine"]))):
        r[1] = f"-{r[1]}"
    return {k: [tuple(x) for x in v] for k, v in d.items()}


def main():
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = random.Random(SEED)
    data = build(rng)
    clean = out_dir / "kutubxona_v2.sqlite"
    messy = out_dir / "kutubxona_messy.sqlite"
    write_db(clean, SCHEMA, data)
    write_db(messy, MESSY_SCHEMA, make_messy(random.Random(SEED + 1), data))
    print(f"Created {clean}: {len(data['member'])} members, {len(data['book'])} books, "
          f"{len(data['loan'])} loans, {len(data['reservation'])} reservations, "
          f"{len(data['fine'])} fines (dates from {START} to {TODAY}).")
    print(f"Created {messy}: same data with cleaning problems to find.")


if __name__ == "__main__":
    main()
