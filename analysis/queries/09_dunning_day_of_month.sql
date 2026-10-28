-- title: Day of month of payment_failed cancellations (dunning window)
-- description: Tests whether the spike starting 2026-09-09 is tied to release 4.8.0 (same day) or to the normal dunning cycle.
SELECT CASE WHEN canceled_at < '2026-09-01' THEN 'Feb-Aug' ELSE substr(canceled_at, 1, 7) END AS period,
       CAST(substr(canceled_at, 9, 2) AS INTEGER) AS day_of_month,
       COUNT(*) AS payment_failed_cancellations
FROM subscriptions
WHERE cancel_reason = 'payment_failed'
GROUP BY period, day_of_month
ORDER BY period, day_of_month;
