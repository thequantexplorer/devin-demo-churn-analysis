-- title: Churn by region x payment method and month (the interaction)
-- description: Isolates the cell touched by release 4.7.0 (EU + card) and its natural controls (EU + invoice, non-EU + card).
WITH months(m) AS (
  VALUES ('2026-03'),('2026-04'),('2026-05'),('2026-06'),('2026-07'),('2026-08'),('2026-09'),('2026-10')
),
pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id),
grid AS (
  SELECT m.m AS month, a.region, pm.payment_method, s.mrr_cents,
         (s.started_at <= m.m || '-01' AND (s.canceled_at IS NULL OR s.canceled_at >= m.m || '-01')) AS active_start,
         (substr(s.canceled_at, 1, 7) = m.m) AS canceled_in_month
  FROM months m CROSS JOIN subscriptions s
  JOIN accounts a ON a.id = s.account_id
  JOIN pm ON pm.account_id = s.account_id
)
SELECT region, payment_method, month,
       SUM(active_start)                                             AS active_start,
       SUM(canceled_in_month)                                        AS cancellations,
       ROUND(100.0 * SUM(canceled_in_month) / SUM(active_start), 2)  AS logo_churn_pct,
       COALESCE(SUM(CASE WHEN canceled_in_month THEN mrr_cents END), 0) / 100 AS lost_mrr_usd
FROM grid
GROUP BY region, payment_method, month
ORDER BY region, payment_method, month;
