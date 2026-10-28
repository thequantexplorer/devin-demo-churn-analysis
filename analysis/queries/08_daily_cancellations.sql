-- title: Daily cancellations, Jul-Oct 2026, split EU-card payment failures vs everything else
-- description: Used to line the spike up against release dates (4.7.0 on 2026-08-18, 4.8.0 on 2026-09-09).
WITH pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id)
SELECT s.canceled_at AS day,
       SUM(a.region = 'EU' AND pm.payment_method = 'card' AND s.cancel_reason = 'payment_failed')        AS eu_card_payment_failed,
       SUM(NOT (a.region = 'EU' AND pm.payment_method = 'card' AND s.cancel_reason = 'payment_failed'))  AS all_other
FROM subscriptions s
JOIN accounts a ON a.id = s.account_id
JOIN pm ON pm.account_id = s.account_id
WHERE s.canceled_at BETWEEN '2026-07-01' AND '2026-10-31'
GROUP BY s.canceled_at
ORDER BY s.canceled_at;
