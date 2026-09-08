-- interaction_hub_email_kpis
-- Daily email volumes for the Interaction Hub Emails tab KPI strip: how many emails
-- AnyVan sent per class and per type per day (system-wide, not customer-scoped).
--   Transactional = EVENTS_MESSAGING_MESSAGE (CHANNEL='EMAIL'), by TEMPLATE_KEY.
--   Marketing     = EVENTS_EMAIL (EMAIL_EVENT_TYPE='sent'), by campaign (PAYLOAD:emailName).
-- The UI rolls these up into tiles (today / N-day totals by class) and a by-type table.
-- Params: :days
SELECT
    'Transactional'                        AS EMAIL_CLASS,
    m.EVENT_DATE                           AS EVENT_DATE,
    m.TEMPLATE_KEY                         AS EMAIL_TYPE,
    COUNT(DISTINCT m.MESSAGE_ID)           AS N_SENT
FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE m
WHERE m.CHANNEL = 'EMAIL'
  AND m.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
GROUP BY 1, 2, 3
UNION ALL
SELECT
    'Marketing',
    e.EVENT_DATE,
    COALESCE(e.PAYLOAD:emailName::string, '(campaign)'),
    COUNT(DISTINCT e.PAYLOAD:emailEventId::string)
FROM HARMONISED.PRODUCTION.EVENTS_EMAIL e
WHERE e.EMAIL_EVENT_TYPE = 'sent'
  AND e.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY EVENT_DATE DESC, N_SENT DESC
