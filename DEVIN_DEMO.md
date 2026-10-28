# Devin demo: Churn investigation with an interactive report

**What it shows:** Devin queries a SQLite warehouse to explain a churn spike, tests competing explanations against release notes and support tickets, and delivers an interactive HTML report with the SQL behind every number.

**Needs:** GitHub only

More demos: [devin-advanced-demos](https://github.com/thequantexplorer/devin-advanced-demos)

## Set it up

1. Click **Use this template → Create a new repository** (or fork it) into your own GitHub account or org.
2. In Devin, open [**Settings → Connections → GitHub**](https://app.devin.ai/settings/connections/github) and make sure Devin can access the new repository.

## Prompt

Start a new Devin session and paste this. Replace `<you>` with your GitHub user or org.

```text
Our CFO noticed churn roughly tripled in September 2026 and needs to know why before the board meeting. The data is in https://github.com/<you>/devin-demo-churn-analysis (SQLite warehouse snapshot, see README).

Investigate like a senior analyst: quantify the spike, segment it (region, plan, channel, payment method, cancel reason), test competing hypotheses against the release notes and support tickets, and separate correlation from causation. Deliver an interactive HTML report (charts, filterable tables, the SQL behind every number) with an executive summary up top, a root-cause conclusion with confidence level, the size of the revenue impact, and 3 concrete recommendations. Commit the report and the queries to the repo in a PR.
```
