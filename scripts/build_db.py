"""Builds data/metrics.db: a snapshot of Acme Cloud's billing + product warehouse (Jan-Oct 2026)."""
import random, sqlite3, datetime as dt, os

random.seed(2026)
path = os.path.join(os.path.dirname(__file__), '..', 'data', 'metrics.db')
if os.path.exists(path):
    os.remove(path)
db = sqlite3.connect(path)
db.executescript("""
CREATE TABLE accounts (id INTEGER PRIMARY KEY, name TEXT, region TEXT, plan TEXT, seats INTEGER, signup_date TEXT, acquisition_channel TEXT);
CREATE TABLE subscriptions (id INTEGER PRIMARY KEY, account_id INTEGER, plan TEXT, mrr_cents INTEGER, started_at TEXT, canceled_at TEXT, cancel_reason TEXT);
CREATE TABLE invoices (id INTEGER PRIMARY KEY, account_id INTEGER, period TEXT, amount_cents INTEGER, status TEXT, attempts INTEGER, payment_method TEXT);
CREATE TABLE usage_daily (account_id INTEGER, day TEXT, active_users INTEGER, api_calls INTEGER);
CREATE TABLE support_tickets (id INTEGER PRIMARY KEY, account_id INTEGER, created_at TEXT, category TEXT, sentiment REAL, subject TEXT);
CREATE TABLE releases (version TEXT, released_at TEXT, notes TEXT);
""")
plans = {'starter': 2900, 'team': 9900, 'business': 39900}
regions = ['NA', 'EU', 'APAC', 'LATAM']
channels = ['organic', 'paid_search', 'partner', 'outbound']
releases = [
    ('4.2.0', '2026-03-10', 'New onboarding checklist'),
    ('4.5.0', '2026-06-02', 'Usage-based API add-on'),
    ('4.7.0', '2026-08-18', 'Billing: migrated EU card payments to new PSP (SCA / 3-D Secure flow)'),
    ('4.8.0', '2026-09-09', 'Dark mode; Team plan price change $99 -> $129 for new signups only'),
]
db.executemany('INSERT INTO releases VALUES (?,?,?)', releases)

start = dt.date(2026, 1, 1)
end = dt.date(2026, 10, 31)
acc_id = sub_id = inv_id = tik_id = 0
subjects = {
    'billing': ['Card declined but my card works', 'Payment failed again', 'Why was my account suspended?', '3-D Secure popup never appears', 'Invoice unpaid?'],
    'product': ['Feature request: SSO', 'Export to CSV is slow', 'Dashboard bug', 'Love the new dark mode'],
    'pricing': ['Price went up?', 'Discount for nonprofits'],
}
def month_iter(d0, d1):
    d = dt.date(d0.year, d0.month, 1)
    while d <= d1:
        yield d
        d = dt.date(d.year + (d.month // 12), d.month % 12 + 1, 1)

for day_offset in range((end - start).days + 1):
    day = start + dt.timedelta(days=day_offset)
    for _ in range(random.randint(3, 7)):
        acc_id += 1
        region = random.choices(regions, [45, 30, 15, 10])[0]
        plan = random.choices(list(plans), [55, 35, 10])[0]
        seats = {'starter': random.randint(1, 5), 'team': random.randint(5, 40), 'business': random.randint(30, 300)}[plan]
        db.execute('INSERT INTO accounts VALUES (?,?,?,?,?,?,?)', (acc_id, f'Account {acc_id}', region, plan, seats, day.isoformat(), random.choice(channels)))
        price = plans[plan]
        if plan == 'team' and day >= dt.date(2026, 9, 9):
            price = 12900
        mrr = price if plan != 'business' else price + seats * 500
        # baseline voluntary churn hazard per month
        canceled_at = reason = None
        pay_method = 'card' if random.random() < 0.85 else 'invoice'
        for m in month_iter(day, end):
            if m < dt.date(day.year, day.month, 1):
                continue
            period = m.strftime('%Y-%m')
            inv_id += 1
            # The real story: after 4.7.0 (2026-08-18) EU card renewals fail SCA silently -> involuntary churn
            eu_bug = region == 'EU' and pay_method == 'card' and m >= dt.date(2026, 9, 1)
            fail_p = 0.03 + (0.38 if eu_bug else 0)
            failed = random.random() < fail_p and m > dt.date(day.year, day.month, 1)
            attempts = random.randint(3, 4) if failed else 1
            status = 'uncollectible' if failed and random.random() < 0.8 else 'paid'
            db.execute('INSERT INTO invoices VALUES (?,?,?,?,?,?,?)', (inv_id, acc_id, period, mrr, status, attempts, pay_method))
            if failed and random.random() < 0.6:
                tik_id += 1
                db.execute('INSERT INTO support_tickets VALUES (?,?,?,?,?,?)', (tik_id, acc_id, (m + dt.timedelta(days=random.randint(1, 6))).isoformat(), 'billing', round(random.uniform(-0.9, -0.4), 2), random.choice(subjects['billing'])))
            if status == 'uncollectible':
                canceled_at = (m + dt.timedelta(days=random.randint(8, 20))).isoformat()
                reason = 'payment_failed'
                break
            vol_p = {'starter': 0.035, 'team': 0.02, 'business': 0.008}[plan]
            if plan == 'team' and day >= dt.date(2026, 9, 9):
                vol_p += 0.01  # price change: small, real, but not the main driver
            if random.random() < vol_p and m > dt.date(day.year, day.month, 1):
                canceled_at = (m + dt.timedelta(days=random.randint(1, 27))).isoformat()
                reason = random.choice(['too_expensive', 'missing_feature', 'switched_competitor', 'no_longer_needed'])
                break
            if random.random() < 0.05:
                tik_id += 1
                cat = random.choice(['product', 'product', 'pricing'])
                db.execute('INSERT INTO support_tickets VALUES (?,?,?,?,?,?)', (tik_id, acc_id, (m + dt.timedelta(days=random.randint(1, 27))).isoformat(), cat, round(random.uniform(-0.5, 0.8), 2), random.choice(subjects[cat])))
        if canceled_at and canceled_at > end.isoformat():
            canceled_at, reason = None, None
        sub_id += 1
        db.execute('INSERT INTO subscriptions VALUES (?,?,?,?,?,?,?)', (sub_id, acc_id, plan, mrr, day.isoformat(), canceled_at, reason))

# light usage table: weekly samples to keep the file small
rows = []
for (aid, signup, plan, seats) in db.execute('SELECT id, signup_date, plan, seats FROM accounts').fetchall():
    if aid % 4:
        continue
    d = dt.date.fromisoformat(signup)
    while d <= end:
        rows.append((aid, d.isoformat(), max(1, int(seats * random.uniform(0.3, 0.9))), random.randint(50, 5000)))
        d += dt.timedelta(days=7)
db.executemany('INSERT INTO usage_daily VALUES (?,?,?,?)', rows)
db.commit()
print('accounts', acc_id, 'invoices', inv_id, 'tickets', tik_id, 'usage rows', len(rows))
