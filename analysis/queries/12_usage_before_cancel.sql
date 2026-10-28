-- title: Product engagement of September-October churners before they canceled
-- description: Seat utilization (weekly active users / seats) in the 8 weeks before cancellation vs the 8 weeks before that. usage_daily covers a 25% sample of accounts, so n is small.
WITH pm AS (SELECT account_id, MAX(payment_method) AS payment_method FROM invoices GROUP BY account_id),
churners AS (
  SELECT s.account_id, s.canceled_at, a.seats,
         CASE WHEN a.region = 'EU' AND pm.payment_method = 'card' AND s.cancel_reason = 'payment_failed'
              THEN 'EU card, payment_failed' ELSE 'All other churners' END AS grp
  FROM subscriptions s
  JOIN accounts a ON a.id = s.account_id
  JOIN pm ON pm.account_id = s.account_id
  WHERE s.canceled_at >= '2026-09-01'
),
per_account AS (
  SELECT c.grp, c.account_id,
         AVG(CASE WHEN u.day BETWEEN date(c.canceled_at, '-56 days') AND date(c.canceled_at, '-1 day')
                  THEN 1.0 * u.active_users / c.seats END)  AS util_last_8w,
         AVG(CASE WHEN u.day BETWEEN date(c.canceled_at, '-112 days') AND date(c.canceled_at, '-57 days')
                  THEN 1.0 * u.active_users / c.seats END)  AS util_prior_8w
  FROM churners c
  JOIN usage_daily u ON u.account_id = c.account_id
  GROUP BY c.grp, c.account_id
)
SELECT grp,
       COUNT(*)                              AS sampled_accounts,
       ROUND(100 * AVG(util_prior_8w), 1)    AS seat_util_pct_prior_8w,
       ROUND(100 * AVG(util_last_8w), 1)     AS seat_util_pct_last_8w
FROM per_account
GROUP BY grp
UNION ALL
SELECT 'Retained accounts (Aug-Oct)',
       COUNT(DISTINCT u.account_id), NULL,
       ROUND(100 * AVG(1.0 * u.active_users / a.seats), 1)
FROM usage_daily u
JOIN accounts a ON a.id = u.account_id
JOIN subscriptions s ON s.account_id = u.account_id
WHERE s.canceled_at IS NULL AND u.day >= '2026-08-01';
