-- title: Monthly logo and MRR churn, Feb-Oct 2026
-- description: Churn rate = subscriptions canceled in the month / subscriptions active on the 1st of the month. MRR churn uses the same denominator weighted by MRR.
WITH months(m) AS (
  VALUES ('2026-02'),('2026-03'),('2026-04'),('2026-05'),('2026-06'),
         ('2026-07'),('2026-08'),('2026-09'),('2026-10')
),
grid AS (
  SELECT m.m AS month, s.*,
         (s.started_at <= m.m || '-01' AND (s.canceled_at IS NULL OR s.canceled_at >= m.m || '-01')) AS active_start,
         (substr(s.canceled_at, 1, 7) = m.m) AS canceled_in_month
  FROM months m CROSS JOIN subscriptions s
)
SELECT month,
       SUM(active_start)                                                   AS active_start,
       SUM(canceled_in_month)                                              AS cancellations,
       ROUND(100.0 * SUM(canceled_in_month) / SUM(active_start), 2)        AS logo_churn_pct,
       SUM(CASE WHEN active_start THEN mrr_cents END) / 100                AS mrr_start_usd,
       COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0) / 100 AS lost_mrr_usd,
       ROUND(100.0 * COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0)
             / SUM(CASE WHEN active_start THEN mrr_cents END), 2)          AS mrr_churn_pct,
       SUM(substr(started_at, 1, 7) = month)                               AS new_subscriptions
FROM grid
GROUP BY month
ORDER BY month;
