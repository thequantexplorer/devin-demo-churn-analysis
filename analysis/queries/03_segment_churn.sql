-- title: Churn rate by segment and month (region, plan, channel, payment method)
-- description: One row per dimension x segment x month. Payment method is the account's invoice payment method (each account uses exactly one).
WITH months(m) AS (
  VALUES ('2026-03'),('2026-04'),('2026-05'),('2026-06'),('2026-07'),('2026-08'),('2026-09'),('2026-10')
),
pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id),
subs AS (
  SELECT s.*, a.region, a.acquisition_channel, pm.payment_method
  FROM subscriptions s
  JOIN accounts a ON a.id = s.account_id
  JOIN pm ON pm.account_id = s.account_id
),
long AS (
  SELECT 'region' AS dimension, region AS segment, * FROM subs
  UNION ALL SELECT 'plan', plan, * FROM subs
  UNION ALL SELECT 'channel', acquisition_channel, * FROM subs
  UNION ALL SELECT 'payment_method', payment_method, * FROM subs
),
grid AS (
  SELECT m.m AS month, l.dimension, l.segment, l.mrr_cents,
         (l.started_at <= m.m || '-01' AND (l.canceled_at IS NULL OR l.canceled_at >= m.m || '-01')) AS active_start,
         (substr(l.canceled_at, 1, 7) = m.m) AS canceled_in_month
  FROM months m CROSS JOIN long l
)
SELECT dimension, segment, month,
       SUM(active_start)                                                AS active_start,
       SUM(canceled_in_month)                                           AS cancellations,
       ROUND(100.0 * SUM(canceled_in_month) / SUM(active_start), 2)     AS logo_churn_pct,
       COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0) / 100 AS lost_mrr_usd
FROM grid
GROUP BY dimension, segment, month
ORDER BY dimension, segment, month;
