-- title: Headline: September vs August and vs the Mar-Aug baseline
-- description: Baseline is the pooled Mar-Aug rate (total cancellations / total active-at-start subscription-months).
WITH months(m) AS (
  VALUES ('2026-03'),('2026-04'),('2026-05'),('2026-06'),('2026-07'),('2026-08'),('2026-09'),('2026-10')
),
grid AS (
  SELECT m.m AS month,
         CASE WHEN m.m BETWEEN '2026-03' AND '2026-08' THEN 'baseline_mar_aug' ELSE m.m END AS period,
         s.mrr_cents,
         (s.started_at <= m.m || '-01' AND (s.canceled_at IS NULL OR s.canceled_at >= m.m || '-01')) AS active_start,
         (substr(s.canceled_at, 1, 7) = m.m) AS canceled_in_month
  FROM months m CROSS JOIN subscriptions s
)
SELECT period,
       SUM(active_start)                                             AS active_sub_months,
       SUM(canceled_in_month)                                        AS cancellations,
       ROUND(100.0 * SUM(canceled_in_month) / SUM(active_start), 2)  AS logo_churn_pct,
       ROUND(100.0 * COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0)
             / SUM(CASE WHEN active_start THEN mrr_cents END), 2)    AS mrr_churn_pct
FROM grid
WHERE month IN ('2026-03','2026-04','2026-05','2026-06','2026-07','2026-08','2026-09','2026-10')
GROUP BY period
UNION ALL
SELECT '2026-08', SUM(active_start), SUM(canceled_in_month),
       ROUND(100.0 * SUM(canceled_in_month) / SUM(active_start), 2),
       ROUND(100.0 * COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0)
             / SUM(CASE WHEN active_start THEN mrr_cents END), 2)
FROM grid WHERE month = '2026-08'
ORDER BY period;
