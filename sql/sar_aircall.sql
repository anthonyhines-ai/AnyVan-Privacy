------------------------------------------------------------------------------
-- sar_aircall  (AV Dashboards named query; param :phone_suffix)
-- Aircall voice calls for the customer incl. the in-warehouse RECORDING url,
-- matched on the last 10 phone digits of RAW_DIGITS. (Twilio calls are already
-- covered by sar_calls; Aircall holds the recording link that sar_calls lacks.)
-- Target dashboard: operations/sar-data-extract  (tab: Aircall)
-- STATUS: authored from confirmed schema; validate in Snowflake before deploy
--         (confirm STARTED_AT text format for display).
------------------------------------------------------------------------------
SELECT
  STARTED_AT,
  ANSWERED_AT,
  ENDED_AT,
  DIRECTION,
  STATUS,
  RAW_DIGITS,
  DURATION,
  RECORDING           AS RECORDING_URL,
  MISSED_CALL_REASON,
  SID,
  SYNCED_DATE
FROM HARMONISED.PRODUCTION.AIRCALL_CALL
WHERE COALESCE(DELETED_ROW, FALSE) = FALSE
  AND RIGHT(REGEXP_REPLACE(COALESCE(RAW_DIGITS,''), '[^0-9]', ''), 10) = :phone_suffix
ORDER BY SYNCED_DATE DESC
LIMIT 5000
