------------------------------------------------------------------------------
-- sar_calls_all  (AV Dashboards named query; param :phone_suffix)
-- CONSOLIDATED "Calls" tab for the SAR extract dashboard. One row per call,
-- tagged with a TYPE column, across every voice source we hold:
--   Twilio     -> HARMONISED.PRODUCTION.TWILIO_CALL                 (Twilio voice)
--   Aircall    -> HARMONISED.PRODUCTION.AIRCALL_CALL                (incl. RECORDING url)
--   Transcript -> CONFORMED.PRODUCTION.CALL_TRANSCRIPT_SEGMENTS     (aggregated per call)
-- Replaces the per-source queries: sar_calls, sar_aircall, sar_call_transcripts.
-- Matched on the last 10 phone digits (:phone_suffix). Text columns cast ::string
-- and timestamps ::TIMESTAMP_NTZ so the UNION arms share one type per column.
-- Shared column contract: OCCURRED_AT, TYPE, SUBJECT, STATUS, BODY, REFERENCE, DETAIL.
-- STATUS: Snowflake-validated (compiles; dummy :phone_suffix -> 0 rows, no PII).
------------------------------------------------------------------------------
SELECT * FROM (
  -- Twilio voice calls
  SELECT
    c.START_TIME::TIMESTAMP_NTZ                              AS OCCURRED_AT,
    'Twilio'                                                 AS TYPE,
    CAST(NULL AS VARCHAR)                                    AS SUBJECT,
    (c.DIRECTION || ' / ' || c.STATUS)::string               AS STATUS,
    CAST(NULL AS VARCHAR)                                    AS BODY,
    c.ID::string                                            AS REFERENCE,
    ('From ' || COALESCE(c."FROM", '') || ' To ' || COALESCE(c."TO", '')
      || ' (' || COALESCE(c.DURATION::string, '?') || 's)')::string AS DETAIL
  FROM HARMONISED.PRODUCTION.TWILIO_CALL c
  WHERE RIGHT(REGEXP_REPLACE(c."FROM", '[^0-9]', ''), 10) = :phone_suffix
     OR RIGHT(REGEXP_REPLACE(c."TO",   '[^0-9]', ''), 10) = :phone_suffix

  UNION ALL
  -- Aircall calls (carry the in-warehouse recording url)
  SELECT
    COALESCE(TRY_TO_TIMESTAMP(a.STARTED_AT::string), a.SYNCED_DATE)::TIMESTAMP_NTZ,
    'Aircall',
    CAST(NULL AS VARCHAR),
    (a.DIRECTION || ' / ' || a.STATUS)::string,
    a.MISSED_CALL_REASON::string,
    a.SID::string,
    a.RECORDING::string
  FROM HARMONISED.PRODUCTION.AIRCALL_CALL a
  WHERE COALESCE(a.DELETED_ROW, FALSE) = FALSE
    AND RIGHT(REGEXP_REPLACE(COALESCE(a.RAW_DIGITS, ''), '[^0-9]', ''), 10) = :phone_suffix

  UNION ALL
  -- Call transcripts, aggregated to one row per call
  SELECT
    MIN(t.EVENT_TIMESTAMP)::TIMESTAMP_NTZ,
    'Transcript',
    ('Transcript (' || COUNT(*) || ' segments)')::string,
    ANY_VALUE(t.AGENT_NAME_RAW)::string,
    LISTAGG(t.SPEAKER || ': ' || t.SEGMENT_TEXT, '  |  ') WITHIN GROUP (ORDER BY t.SEGMENT_INDEX)::string,
    t.CALL_SID::string,
    ANY_VALUE(t.AGENT_TEAM)::string
  FROM CONFORMED.PRODUCTION.CALL_TRANSCRIPT_SEGMENTS t
  WHERE RIGHT(REGEXP_REPLACE(t.CUSTOMER_PHONE_DIGITS, '[^0-9]', ''), 10) = :phone_suffix
  GROUP BY t.CALL_SID
)
ORDER BY OCCURRED_AT DESC
LIMIT 5000
