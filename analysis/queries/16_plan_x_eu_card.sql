-- title: September churn by plan, split EU + card vs everyone else
-- description: Checks whether the Team (or any plan) increase is a pricing effect or the EU card payment failure showing up inside the plan.
WITH pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id)
SELECT s.plan,
       CASE WHEN a.region = 'EU' AND pm.payment_method = 'card' THEN 'EU / card' ELSE 'All other' END AS grp,
       SUM(s.started_at <= '2026-09-01' AND (s.canceled_at IS NULL OR s.canceled_at >= '2026-09-01')) AS active_sep1,
       SUM(substr(s.canceled_at, 1, 7) = '2026-09')                                                   AS sep_cancellations,
       ROUND(100.0 * SUM(substr(s.canceled_at, 1, 7) = '2026-09')
             / SUM(s.started_at <= '2026-09-01' AND (s.canceled_at IS NULL OR s.canceled_at >= '2026-09-01')), 2) AS sep_churn_pct
FROM subscriptions s
JOIN accounts a ON a.id = s.account_id
JOIN pm ON pm.account_id = s.account_id
GROUP BY s.plan, grp
ORDER BY s.plan, grp;
