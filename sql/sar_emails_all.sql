------------------------------------------------------------------------------
-- sar_emails_all  (AV Dashboards named query; param :email)
-- CONSOLIDATED "Emails" tab for the SAR extract dashboard. One row per email
-- event, tagged with a TYPE column, across every email source we hold:
--   Marketing     -> HARMONISED.PRODUCTION.EVENTS_EMAIL            (HubSpot marketing events)
--   Transactional -> HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE (CHANNEL='EMAIL', body+subject; 2026-05-19+)
--   System log    -> HARMONISED.PRODUCTION.LISTING_COMMUNICATION    (CHANNEL email send-log; 2022+)
--   Pre-Listing   -> HARMONISED.PRODUCTION.PRE_LISTING_EMAIL(_LOG)  (quote/enquiry emails)
-- Replaces the per-source queries: sar_hubspot_emails, sar_messaging (email rows),
-- sar_listing_comms / sar_comms_log (email rows), sar_prelisting_emails.
-- Shared column contract: OCCURRED_AT, TYPE, SUBJECT, STATUS, BODY, REFERENCE, DETAIL.
-- STATUS: validate in Snowflake with a dummy :email before deploy.
------------------------------------------------------------------------------
WITH u AS (
  SELECT USER_ID
  FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
  WHERE LOWER(EMAIL_ADDRESS) = LOWER(:email)
)
SELECT * FROM (
  -- Marketing (HubSpot email events)
  SELECT
    e.EVENT_TIMESTAMP                             AS OCCURRED_AT,
    'Marketing'                                   AS TYPE,
    e.EMAIL_SUBJECT                               AS SUBJECT,
    e.EMAIL_EVENT_TYPE                            AS STATUS,
    CAST(NULL AS VARCHAR)                         AS BODY,
    e.EVENT_ID::string                            AS REFERENCE,
    e.EVENT_SOURCE                                AS DETAIL
  FROM HARMONISED.PRODUCTION.EVENTS_EMAIL e
  WHERE LOWER(e.EMAIL_ADDRESS) = LOWER(:email)

  UNION ALL
  -- Transactional (messaging platform, email channel)
  SELECT
    m.EVENT_TIMESTAMP,
    'Transactional',
    m.RENDERED_SUBJECT,
    m.EVENT_NAME,
    m.MESSAGE,
    m.REQUEST_METADATA_CONTEXT:listingId::string,
    'template=' || COALESCE(m.TEMPLATE_KEY, '')
  FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE m
  WHERE LOWER(m.RESOLVED_USER_EMAIL) = LOWER(:email)
    AND m.CHANNEL = 'EMAIL'

  UNION ALL
  -- System send-log (listing communications, email channel)
  SELECT
    lc.CREATED_AT,
    'System log',
    TRY_PARSE_JSON(lc.TOKENS):subject::string,
    lc.STATUS,
    lc.DETAILS,
    lc.LISTING_ID::string,
    lc.TYPE
  FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
  JOIN u ON u.USER_ID = lc.RECIPIENT_ID
  WHERE COALESCE(lc.DELETED_ROW, FALSE) = FALSE
    AND lc.CHANNEL ILIKE 'email'

  UNION ALL
  -- Pre-Listing (quote/enquiry) emails
  SELECT
    pel.SENT_AT,
    'Pre-Listing',
    pel.TEMPLATE,
    CASE WHEN pel.IS_AUTO THEN 'auto' ELSE 'manual' END,
    CAST(NULL AS VARCHAR),
    pe.PRE_LISTING_ID::string,
    pe.NAME
  FROM HARMONISED.PRODUCTION.PRE_LISTING_EMAIL pe
  JOIN HARMONISED.PRODUCTION.PRE_LISTING_EMAIL_LOG pel
    ON pe.PRE_LISTING_EMAIL_ID = pel.PRE_LISTING_EMAIL_ID
   AND COALESCE(pel.DELETED_ROW, FALSE) = FALSE
  WHERE LOWER(pe.EMAIL) = LOWER(:email)
    AND COALESCE(pe.DELETED_ROW, FALSE) = FALSE
)
ORDER BY OCCURRED_AT DESC
LIMIT 5000
