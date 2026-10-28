# acme-saas-metrics

Read-only snapshot of Acme Cloud's billing + product warehouse (Jan–Oct 2026) as SQLite: `data/metrics.db`.

| table | what |
| --- | --- |
| `accounts` | one row per customer account (region, plan, seats, signup date, channel) |
| `subscriptions` | plan, MRR, start, cancel date + reason |
| `invoices` | monthly invoices, status, payment attempts, payment method |
| `usage_daily` | weekly active-user / API-call samples (25% of accounts) |
| `support_tickets` | ticket category, sentiment, subject |
| `releases` | product releases with notes |

```sh
sqlite3 data/metrics.db ".tables"
python3 scripts/build_db.py   # regenerates the snapshot deterministically
```

Context: the CFO noticed churn roughly tripled in September 2026 and wants to know why before the board meeting.

---

This repo is a starter for a Devin demo. See [DEVIN_DEMO.md](DEVIN_DEMO.md) for setup and the prompt.
