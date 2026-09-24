------------------------------------------------------------------------------
-- sar_calls_all  (AV Dashboards named query; param :phone_suffix)
-- CONSOLIDATED "Calls" tab for the SAR extract dashboard. One row per call,
-- tagged with a TYPE column, across every voice source we hold:
--   Twilio     -> HARMONISED.PRODUCTION.TWILIO_CALL                 (Twilio voice)
--   Aircall    -> HARMONISED.PRODUCTION.AIRCALL_CALL                (incl. RECORDING url)
--   Transcript -> CONFORMED.PRODUCTION.CALL_TRANSCRIPT_SEGMENTS     (aggregated per call)
-- Replaces the per-source queries: sar_calls, sar_aircall, sar_call_transcripts.
-- Matched on the last 10 phone digits (:phone_suffix).
-- Shared column contract: OCCURRED_AT, TYPE, SUBJECT, STATUS, BODY, REFERENCE, DETAIL.
-- STATUS: validate in Snowflake with a dummy :phone_suffix before deploy.
------------------------------------------------------------------------------
SELECT * FROM (
  -- Twilio voice calls
  SELECT
    c.START_TIME                                              AS OCCURRED_AT,
    'Twilio'                                                  AS TYPE,
    CAST(NULL AS VARCHAR)                                     AS SUBJECT,
    c.DIRECTION || ' / ' || c.STATUS                          AS STATUS,
    CAST(NULL AS VARCHAR)                                     AS BODY,
    c.ID::string                                             AS REFERENCE,
    'From ' || COALESCE(c."FROM", '') || ' To ' || COALESCE(c."TO", '')
      || ' (' || COALESCE(c.DURATION::string, '?') || 's)'    AS DETAIL
  FROM HARMONISED.PRODUCTION.TWILIO_CALL c
  WHERE RIGHT(REGEXP_REPLACE(c."FROM", '[^0-9]', ''), 10) = :phone_suffix
     OR RIGHT(REGEXP_REPLACE(c."TO",   '[^0-9]', ''), 10) = :phone_suffix

  UNION ALL
  -- Aircall calls (carry the in-warehouse recording url)
  SELECT
    COALESCE(TRY_TO_TIMESTAMP(a.STARTED_AT::string), a.SYNCED_DATE),
    'Aircall',
    CAST(NULL AS VARCHAR),
    a.DIRECTION || ' / ' || a.STATUS,
    a.MISSED_CALL_REASON,
    a.SID::string,
    a.RECORDING
  FROM HARMONISED.PRODUCTION.AIRCALL_CALL a
  WHERE COALESCE(a.DELETED_ROW, FALSE) = FALSE
    AND RIGHT(REGEXP_REPLACE(COALESCE(a.RAW_DIGITS, ''), '[^0-9]', ''), 10) = :phone_suffix

  UNION ALL
  -- Call transcripts, aggregated to one row per call
  SELECT
    MIN(t.EVENT_TIMESTAMP),
    'Transcript',
    'Transcript (' || COUNT(*) || ' segments)',
    ANY_VALUE(t.AGENT_NAME_RAW),
    LISTAGG(t.SPEAKER || ': ' || t.SEGMENT_TEXT, '  |  ') WITHIN GROUP (ORDER BY t.SEGMENT_INDEX),
    t.CALL_SID::string,
    ANY_VALUE(t.AGENT_TEAM)
  FROM CONFORMED.PRODUCTION.CALL_TRANSCRIPT_SEGMENTS t
  WHERE RIGHT(REGEXP_REPLACE(t.CUSTOMER_PHONE_DIGITS, '[^0-9]', ''), 10) = :phone_suffix
  GROUP BY t.CALL_SID
)
ORDER BY OCCURRED_AT DESC
LIMIT 5000
