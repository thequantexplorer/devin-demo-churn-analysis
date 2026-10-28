-- title: Invoice collection by period, region and payment method
-- description: Share of invoices that ended uncollectible, and average payment attempts. This is the mechanism check for the PSP migration.
SELECT i.period,
       a.region,
       i.payment_method,
       COUNT(*)                                                     AS invoices,
       SUM(i.status = 'uncollectible')                              AS uncollectible,
       ROUND(100.0 * SUM(i.status = 'uncollectible') / COUNT(*), 2) AS uncollectible_pct,
       ROUND(AVG(i.attempts), 2)                                    AS avg_attempts,
       SUM(i.attempts > 1)                                          AS invoices_needing_retry
FROM invoices i
JOIN accounts a ON a.id = i.account_id
GROUP BY i.period, a.region, i.payment_method
ORDER BY i.period, a.region, i.payment_method;
