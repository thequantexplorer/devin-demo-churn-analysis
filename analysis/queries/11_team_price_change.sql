-- title: Team plan price change test (4.8.0: $99 -> $129 for new signups only)
-- description: Compares Team subscribers on the old vs new price, and tracks too_expensive cancellations and "Price went up?" tickets.
SELECT 'team_cohort' AS view,
       CASE WHEN mrr_cents = 12900 THEN '$129 (new signups from 2026-09-09)' ELSE '$99 (existing)' END AS segment,
       COUNT(*)                              AS subscriptions,
       SUM(canceled_at >= '2026-09-01')      AS canceled_sep_oct,
       SUM(cancel_reason = 'too_expensive' AND canceled_at >= '2026-09-01') AS too_expensive_sep_oct
FROM subscriptions
WHERE plan = 'team'
GROUP BY segment
UNION ALL
SELECT 'too_expensive_by_month', substr(canceled_at, 1, 7), COUNT(*), NULL, NULL
FROM subscriptions
WHERE cancel_reason = 'too_expensive'
GROUP BY substr(canceled_at, 1, 7)
UNION ALL
SELECT 'price_tickets_by_month', substr(created_at, 1, 7), COUNT(*), NULL, NULL
FROM support_tickets
WHERE subject = 'Price went up?'
GROUP BY substr(created_at, 1, 7)
ORDER BY 1, 2;
