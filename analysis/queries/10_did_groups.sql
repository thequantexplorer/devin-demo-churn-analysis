-- title: Difference-in-differences: EU-card vs control groups, pre (Jun-Aug) vs post (Sep-Oct)
-- description: Monthly churn rate pooled over each window (cancellations / active-at-start subscription-months).
WITH months(m) AS (VALUES ('2026-06'),('2026-07'),('2026-08'),('2026-09'),('2026-10')),
pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id),
grid AS (
  SELECT CASE WHEN m.m <= '2026-08' THEN 'pre_jun_aug' ELSE 'post_sep_oct' END AS window,
         CASE WHEN a.region = 'EU' THEN 'EU' ELSE 'non-EU' END || ' / ' || pm.payment_method AS grp,
         (s.started_at <= m.m || '-01' AND (s.canceled_at IS NULL OR s.canceled_at >= m.m || '-01')) AS active_start,
         (substr(s.canceled_at, 1, 7) = m.m) AS canceled_in_month
  FROM months m CROSS JOIN subscriptions s
  JOIN accounts a ON a.id = s.account_id
  JOIN pm ON pm.account_id = s.account_id
)
SELECT grp, window,
       SUM(active_start)                                             AS active_sub_months,
       SUM(canceled_in_month)                                        AS cancellations,
       ROUND(100.0 * SUM(canceled_in_month) / SUM(active_start), 2)  AS logo_churn_pct
FROM grid
GROUP BY grp, window
ORDER BY grp, window DESC;
