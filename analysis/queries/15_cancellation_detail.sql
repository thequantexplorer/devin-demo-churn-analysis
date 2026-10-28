-- title: Account-level cancellations, Aug-Oct 2026
-- description: Every cancellation since 2026-08-01 with its segment attributes and the payment attempts on its final invoice.
WITH pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id)
SELECT s.account_id,
       a.region,
       s.plan,
       a.acquisition_channel                AS channel,
       pm.payment_method,
       s.cancel_reason,
       s.canceled_at,
       s.mrr_cents / 100                    AS mrr_usd,
       a.seats,
       (SELECT i.status   FROM invoices i WHERE i.account_id = s.account_id ORDER BY i.period DESC LIMIT 1) AS last_invoice_status,
       (SELECT i.attempts FROM invoices i WHERE i.account_id = s.account_id ORDER BY i.period DESC LIMIT 1) AS last_invoice_attempts
FROM subscriptions s
JOIN accounts a ON a.id = s.account_id
JOIN pm ON pm.account_id = s.account_id
WHERE s.canceled_at >= '2026-08-01'
ORDER BY s.canceled_at, s.account_id;
