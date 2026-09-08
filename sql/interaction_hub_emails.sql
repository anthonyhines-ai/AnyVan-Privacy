-- interaction_hub_emails
-- Emails tab (customer-scoped) for the Interaction Hub. Resolves a customer from
-- email/phone/name (same identity fan-out as interaction_hub_identity_lookup) and lists
-- the emails AnyVan sent them, split Transactional vs Marketing. Metadata only — no bodies.
--   Transactional = EVENTS_MESSAGING_MESSAGE (AnyVan's own notification service; CHANNEL='EMAIL',
--                   RENDERED_SUBJECT, TEMPLATE_KEY = email type, keyed by RESOLVED_USER_EMAIL/PHONE).
--   Marketing     = EVENTS_EMAIL (HubSpot; EMAIL_SUBJECT, PAYLOAD:emailName = campaign, keyed by EMAIL_ADDRESS).
-- Params: :mode ('phone'|'email'|'name'), :term_phone10, :term_email, :term_name, :days
WITH cust_seed AS (
    SELECT USER_ID, EMAIL_ADDRESS, PRIMARY_PHONE_NUMBER, SECONDARY_PHONE_NUMBER, FULL_NAME
    FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
    WHERE
        (:mode = 'phone' AND :term_phone10 <> '' AND (
             RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) = :term_phone10
          OR RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) = :term_phone10))
     OR (:mode = 'email' AND :term_email <> '' AND LOWER(EMAIL_ADDRESS) = :term_email)
     OR (:mode = 'name'  AND :term_name  <> '' AND UPPER(TRIM(FULL_NAME)) = :term_name)
),
cust AS (
    SELECT * FROM cust_seed
    WHERE (SELECT COUNT(DISTINCT USER_ID) FROM cust_seed) = 1
),
phones AS (
    SELECT :term_phone10 AS p10 FROM (SELECT 1) WHERE :mode = 'phone' AND LENGTH(:term_phone10) = 10
    UNION
    SELECT RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) FROM cust WHERE PRIMARY_PHONE_NUMBER   IS NOT NULL
    UNION
    SELECT RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) FROM cust WHERE SECONDARY_PHONE_NUMBER IS NOT NULL
),
phones2 AS ( SELECT DISTINCT p10 FROM phones WHERE p10 IS NOT NULL AND LENGTH(p10) = 10 ),
emails AS (
    SELECT :term_email AS em FROM (SELECT 1) WHERE :mode = 'email' AND :term_email <> ''
    UNION
    SELECT LOWER(EMAIL_ADDRESS) FROM cust WHERE EMAIL_ADDRESS IS NOT NULL
),
emails2 AS ( SELECT DISTINCT em FROM emails WHERE em IS NOT NULL AND em <> '' ),
txn AS (
    SELECT
        MIN(CONVERT_TIMEZONE('Europe/London', m.EVENT_TIMESTAMP)::TIMESTAMP_NTZ) AS INTERACTION_DATETIME,
        m.MESSAGE_ID                              AS INTERACTION_ID,
        'Transactional'                           AS EMAIL_CLASS,
        ANY_VALUE(m.TEMPLATE_KEY)                 AS EMAIL_TYPE,
        ANY_VALUE(m.RENDERED_SUBJECT)             AS SUBJECT,
        ANY_VALUE(m.RESOLVED_USER_EMAIL)          AS RECIPIENT,
        ANY_VALUE(m.CHANNEL)                      AS CHANNEL,
        'Outbound'                                AS DIRECTION,
        ANY_VALUE(m.TEMPLATE_KEY)                 AS CAMPAIGN
    FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE m
    WHERE m.CHANNEL = 'EMAIL'
      AND m.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND ( LOWER(m.RESOLVED_USER_EMAIL) IN (SELECT em FROM emails2)
            OR RIGHT(REGEXP_REPLACE(m.RESOLVED_USER_PHONE,'[^0-9]',''),10) IN (SELECT p10 FROM phones2) )
    GROUP BY m.MESSAGE_ID
),
mkt AS (
    SELECT
        CONVERT_TIMEZONE('Europe/London', e.EVENT_TIMESTAMP)::TIMESTAMP_NTZ AS INTERACTION_DATETIME,
        e.PAYLOAD:emailEventId::string            AS INTERACTION_ID,
        'Marketing'                               AS EMAIL_CLASS,
        COALESCE(e.PAYLOAD:emailName::string, '(campaign)') AS EMAIL_TYPE,
        e.EMAIL_SUBJECT                           AS SUBJECT,
        e.EMAIL_ADDRESS                           AS RECIPIENT,
        'EMAIL'                                   AS CHANNEL,
        'Outbound'                                AS DIRECTION,
        e.PAYLOAD:emailName::string               AS CAMPAIGN
    FROM HARMONISED.PRODUCTION.EVENTS_EMAIL e
    WHERE e.EMAIL_EVENT_TYPE = 'sent'
      AND e.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND LOWER(e.EMAIL_ADDRESS) IN (SELECT em FROM emails2)
)
SELECT * FROM txn
UNION ALL SELECT * FROM mkt
ORDER BY INTERACTION_DATETIME DESC
LIMIT 3000
