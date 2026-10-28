# September 2026 churn investigation

Report: [`reports/september_2026_churn_report.html`](../reports/september_2026_churn_report.html). It is a single file; open it in a browser (it loads its UI kit from static.devin.ai).

| path | what |
| --- | --- |
| `analysis/queries/*.sql` | One query per number or chart in the report. Each file starts with a `-- title:` and a `-- description:` line. |
| `analysis/run_queries.py` | Runs every query read-only against `data/metrics.db` and writes `analysis/results.json`, including the significance tests (two-proportion z, Wilson CI, difference-in-differences). |
| `analysis/results.json` | Query outputs. The report is built from this file. |
| `analysis/report/body.html` | Report source (JSX). It is compiled with `results.json` into the HTML report. |

```sh
python3 analysis/run_queries.py            # re-run all queries
sqlite3 data/metrics.db < analysis/queries/05_region_x_payment.sql   # run any single query
```

Definitions: monthly logo churn = subscriptions canceled in the month / subscriptions active on the 1st. MRR churn uses the same denominator, weighted by MRR. Baseline = pooled Mar-Aug 2026. Payment method is per account; every account uses exactly one.
