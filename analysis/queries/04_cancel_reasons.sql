-- title: Cancellations and lost MRR by cancel reason and month
-- description: Every cancellation in the snapshot, grouped by the recorded cancel_reason.
SELECT substr(canceled_at, 1, 7)  AS month,
       cancel_reason,
       COUNT(*)                   AS cancellations,
       SUM(mrr_cents) / 100       AS lost_mrr_usd
FROM subscriptions
WHERE canceled_at IS NOT NULL
GROUP BY month, cancel_reason
ORDER BY month, cancel_reason;
