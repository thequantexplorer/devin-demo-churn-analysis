-- title: Revenue impact of the EU card payment failures
-- description: Excess = actual EU-card lost MRR minus expected lost MRR at the segment's own Mar-Aug MRR churn rate. Also reports EU-card MRR still exposed.
WITH months(m) AS (
  VALUES ('2026-03'),('2026-04'),('2026-05'),('2026-06'),('2026-07'),('2026-08'),('2026-09'),('2026-10')
),
pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id),
eu_card AS (
  SELECT s.* FROM subscriptions s
  JOIN accounts a ON a.id = s.account_id
  JOIN pm ON pm.account_id = s.account_id
  WHERE a.region = 'EU' AND pm.payment_method = 'card'
),
grid AS (
  SELECT m.m AS month, e.mrr_cents,
         (e.started_at <= m.m || '-01' AND (e.canceled_at IS NULL OR e.canceled_at >= m.m || '-01')) AS active_start,
         (substr(e.canceled_at, 1, 7) = m.m) AS canceled_in_month
  FROM months m CROSS JOIN eu_card e
),
monthly AS (
  SELECT month,
         SUM(active_start) AS active_start,
         SUM(canceled_in_month) AS cancellations,
         SUM(CASE WHEN active_start THEN mrr_cents END) / 100.0 AS mrr_start,
         COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0) / 100.0 AS lost_mrr
  FROM grid GROUP BY month
),
baseline AS (
  SELECT 1.0 * SUM(cancellations) / SUM(active_start) AS logo_rate,
         SUM(lost_mrr) / SUM(mrr_start)               AS mrr_rate
  FROM monthly WHERE month BETWEEN '2026-03' AND '2026-08'
)
SELECT m.month,
       m.active_start,
       m.cancellations,
       ROUND(m.active_start * b.logo_rate, 1)                 AS expected_cancellations,
       ROUND(m.cancellations - m.active_start * b.logo_rate)  AS excess_cancellations,
       ROUND(m.lost_mrr)                                      AS lost_mrr_usd,
       ROUND(m.mrr_start * b.mrr_rate)                        AS expected_lost_mrr_usd,
       ROUND(m.lost_mrr - m.mrr_start * b.mrr_rate)           AS excess_lost_mrr_usd,
       ROUND(100 * b.logo_rate, 2)                            AS baseline_logo_churn_pct,
       ROUND(100 * b.mrr_rate, 2)                             AS baseline_mrr_churn_pct,
       (SELECT SUM(mrr_cents) / 100 FROM eu_card WHERE canceled_at IS NULL)  AS eu_card_mrr_still_active_usd,
       (SELECT COUNT(*) FROM eu_card WHERE canceled_at IS NULL)              AS eu_card_subs_still_active,
       (SELECT SUM(mrr_cents) / 100 FROM subscriptions WHERE canceled_at IS NULL) AS total_mrr_active_usd
FROM monthly m CROSS JOIN baseline b
WHERE m.month IN ('2026-09', '2026-10')
ORDER BY m.month;
