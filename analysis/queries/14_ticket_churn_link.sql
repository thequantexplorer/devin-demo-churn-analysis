-- title: Did billing tickets after the PSP migration precede churn?
-- description: Subscriptions active on 2026-09-01, split by whether the account filed a billing ticket on/after 2026-08-18, and the share that canceled in Sep-Oct.
WITH pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id),
ticketed AS (
  SELECT DISTINCT account_id FROM support_tickets
  WHERE category = 'billing' AND created_at >= '2026-08-18'
)
SELECT CASE WHEN a.region = 'EU' AND pm.payment_method = 'card' THEN 'EU / card' ELSE 'All other' END AS grp,
       CASE WHEN t.account_id IS NOT NULL THEN 'billing ticket since 08-18' ELSE 'no billing ticket' END AS ticket_status,
       COUNT(*)                                                        AS subs_active_sep1,
       SUM(s.canceled_at IS NOT NULL)                                  AS canceled_sep_oct,
       ROUND(100.0 * SUM(s.canceled_at IS NOT NULL) / COUNT(*), 1)     AS canceled_pct
FROM subscriptions s
JOIN accounts a ON a.id = s.account_id
JOIN pm ON pm.account_id = s.account_id
LEFT JOIN ticketed t ON t.account_id = s.account_id
WHERE s.started_at <= '2026-09-01' AND (s.canceled_at IS NULL OR s.canceled_at >= '2026-09-01')
GROUP BY grp, ticket_status
ORDER BY grp, ticket_status;
