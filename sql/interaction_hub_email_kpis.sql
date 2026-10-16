-- interaction_hub_email_kpis  (v3 — deployed 2026-09-18)
-- Query ID: 3J3TMkrbacWeSMlRGk1GFJyMJ7R · engine snowflake · public
-- KPI feed for the Emails tab (system-wide, not customer-scoped). Two grains:
--   GRAIN='daily'  -> one row per class per day (tiles + trend)
--   GRAIN='bytype' -> top 15 types per class over the window
-- Sources kept in step with interaction_hub_emails:
--   Transactional = LISTING_COMMUNICATION (email, customer-facing, by TYPE)
--   Marketing     = EVENTS_EMAIL (HubSpot sent)
-- Previously Transactional came from EVENTS_MESSAGING_MESSAGE (gateway) — near-empty, so the
-- Transactional tile read ~0. Param :days
WITH txn AS (
    SELECT CONVERT_TIMEZONE('Europe/London', lc.CREATED_AT)::DATE AS d, lc.TYPE AS typ,
           COUNT(DISTINCT lc.LISTING_COMMUNICATION_ID) AS n
    FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
    WHERE lc.CHANNEL='email' AND lc.TARGET='customer' AND lc.DELETED_ROW=FALSE
      AND lc.CREATED_AT >= DATEADD('day', -1 * :days, CURRENT_DATE())
    GROUP BY 1, 2
),
mkt AS (
    SELECT e.EVENT_DATE AS d, COALESCE(e.PAYLOAD:emailName::string, '(campaign)') AS typ,
           COUNT(DISTINCT e.PAYLOAD:emailEventId::string) AS n
    FROM HARMONISED.PRODUCTION.EVENTS_EMAIL e
    WHERE e.EMAIL_EVENT_TYPE = 'sent' AND e.SOURCE='hubspot' AND e.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
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
