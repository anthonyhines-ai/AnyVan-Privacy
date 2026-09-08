-- interaction_hub_email_kpis
-- Compact KPI feed for the Interaction Hub Emails tab. Returns two grains:
--   GRAIN='daily'  -> one row per class per day (tiles + trend)
--   GRAIN='bytype' -> top 15 types per class over the window
--                     (Transactional = TEMPLATE_KEY, Marketing = campaign name)
-- System-wide (not customer-scoped). Categorised by purpose, never by sending platform.
-- Param :days
WITH txn AS (
    SELECT m.EVENT_DATE AS d, m.TEMPLATE_KEY AS typ, COUNT(DISTINCT m.MESSAGE_ID) AS n
    FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE m
    WHERE m.CHANNEL = 'EMAIL' AND m.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
    GROUP BY 1, 2
),
mkt AS (
    SELECT e.EVENT_DATE AS d, COALESCE(e.PAYLOAD:emailName::string, '(campaign)') AS typ,
           COUNT(DISTINCT e.PAYLOAD:emailEventId::string) AS n
    FROM HARMONISED.PRODUCTION.EVENTS_EMAIL e
    WHERE e.EMAIL_EVENT_TYPE = 'sent' AND e.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
    GROUP BY 1, 2
),
daily AS (
    SELECT 'daily' AS GRAIN, 'Transactional' AS EMAIL_CLASS, TO_VARCHAR(d) AS LABEL, SUM(n) AS N_SENT FROM txn GROUP BY d
    UNION ALL
    SELECT 'daily', 'Marketing', TO_VARCHAR(d), SUM(n) FROM mkt GROUP BY d
),
bytype AS (
    SELECT 'bytype' AS GRAIN, 'Transactional' AS EMAIL_CLASS, typ AS LABEL, SUM(n) AS N_SENT FROM txn GROUP BY typ
    UNION ALL
    SELECT 'bytype', 'Marketing', typ, SUM(n) FROM mkt GROUP BY typ
)
SELECT * FROM daily
UNION ALL
SELECT * FROM bytype QUALIFY ROW_NUMBER() OVER (PARTITION BY EMAIL_CLASS ORDER BY N_SENT DESC) <= 15
ORDER BY GRAIN, EMAIL_CLASS, N_SENT DESC
