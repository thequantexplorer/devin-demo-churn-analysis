-- title: Support tickets by subject and month, with EU share
-- description: Ticket volume and average sentiment per subject. eu_tickets counts tickets from EU accounts.
SELECT substr(t.created_at, 1, 7)    AS month,
       t.category,
       t.subject,
       COUNT(*)                      AS tickets,
       SUM(a.region = 'EU')          AS eu_tickets,
       ROUND(AVG(t.sentiment), 2)    AS avg_sentiment
FROM support_tickets t
JOIN accounts a ON a.id = t.account_id
GROUP BY month, t.category, t.subject
ORDER BY month, t.category, t.subject;
