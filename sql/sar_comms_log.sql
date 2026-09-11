------------------------------------------------------------------------------
-- sar_comms_log  (AV Dashboards named query; param :email)
-- Full transactional send-log across ALL channels (email / sms / whats-app),
-- 2022+, incl. older history before the messaging platform. Body/subject are
-- in TOKENS (JSON). Keyed by RECIPIENT_ID = USER_ID, resolved from the email.
-- Target dashboard: operations/sar-data-extract  (tab: Comms Log)
-- STATUS: authored from confirmed schema; validate in Snowflake before deploy.
------------------------------------------------------------------------------
WITH u AS (
  SELECT USER_ID
  FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
  WHERE LOWER(EMAIL_ADDRESS) = LOWER(:email)
)
SELECT
  lc.CREATED_AT                               AS SENT_AT,
  lc.CHANNEL,
  lc.TYPE                                     AS TEMPLATE,
  TRY_PARSE_JSON(lc.TOKENS):subject::string   AS SUBJECT,
  lc.TARGET,
  lc.LISTING_ID,
  lc.STATUS,
  lc.DETAILS
FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
JOIN u ON u.USER_ID = lc.RECIPIENT_ID
WHERE COALESCE(lc.DELETED_ROW, FALSE) = FALSE
ORDER BY lc.CREATED_AT DESC
LIMIT 5000
