-- interaction_hub_jiminny_calls
-- NEW saved query: SALES calls for a customer phone, sourced from Jiminny (the sales transcript
-- store). Surfaced in the hub's phone-lookup mode alongside interaction_hub_phone_lookup, so a
-- sales call carries the same available/unavailable state + transcript view/search as CS/ops calls.
--
-- Params: :phone_suffix (last 10 digits, as the hub already computes), :days (history window).
--
-- Customer identity: JIMINNY_CALL_METADATA.PARTICIPANTS is a Python-repr array of participants,
-- each carrying a 'phone' field (the agent's is often None / an internal DID). We regex only the
-- quoted phone values (so long numeric ids / transcriptionIds can't false-match), normalise each
-- to its last 10 digits, and match :phone_suffix. matched_phone is shown as CUSTOMER_PHONE.
--
-- Columns mirror interaction_hub_phone_lookup's call rows, plus:
--   TRANSCRIPT_AVAILABLE = TRUE, TRANSCRIPT_SOURCE = 'jiminny'  -> the hub fetches the transcript
--   from interaction_hub_jiminny_transcript by EVENT_ID (= INTERACTION_ID).
-- No RECORDING_URL: Jiminny recordings are not behind the Twilio proxy, so no "Listen" button.

WITH cand AS (
    SELECT m.EVENT_ID, m.ANYVAN_USER_NAME, m.ANYVAN_USER_EMAIL, m.ANYVAN_USER_TEAMNAME,
           m.ACTUAL_START_TIME, m.DURATION_SECONDS, m.STATUS, m.PARTICIPANTS
    FROM HARMONISED.PRODUCTION.JIMINNY_CALL_METADATA m
    WHERE TRY_TO_DATE(LEFT(m.ACTUAL_START_TIME,10)) >= DATEADD('day', -1 * :days, CURRENT_DATE)
      AND m.PARTICIPANTS ILIKE '%''phone''%'
),
matched AS (
    SELECT c.EVENT_ID, ANY_VALUE(f.value::string) AS matched_phone
    FROM cand c,
         LATERAL FLATTEN(input => REGEXP_SUBSTR_ALL(c.PARTICIPANTS, '''phone'':\\s*''([^'']+)''', 1, 1, 'e', 1)) f
    WHERE RIGHT(REGEXP_REPLACE(f.value::string, '[^0-9]', ''), 10) = :phone_suffix
    GROUP BY 1
)
SELECT
    CONVERT_TIMEZONE('UTC','Europe/London', TRY_TO_TIMESTAMP(c.ACTUAL_START_TIME)) AS INTERACTION_DATETIME,
    c.EVENT_ID                                    AS INTERACTION_ID,
    c.ANYVAN_USER_NAME                            AS AGENT_NAME,
    LOWER(c.ANYVAN_USER_EMAIL)                    AS AGENT_EMAIL,
    'Sales'                                        AS AGENT_TYPE,
    m2.matched_phone                              AS CUSTOMER_PHONE,
    NULL::NUMBER                                  AS LISTING_ID,
    NULL::VARCHAR                                 AS COUNTRY,
    NULL::VARCHAR                                 AS LISTING_CATEGORY_NAME,
    NULL::DATE                                    AS PICKUP_DATE,
    NULL::VARCHAR                                 AS LISTING_STATUS,
    NULL::VARCHAR                                 AS SENTIMENT,
    NULL::VARCHAR                                 AS SENTIMENT_SUMMARY,
    NULL::VARCHAR                                 AS INTERACTION_TYPE,
    'Call'                                         AS CHANNEL,
    c.DURATION_SECONDS                            AS DURATION_SECONDS,
    NULL::VARCHAR                                 AS RECORDING_URL,
    NULL::VARCHAR                                 AS RECORDING_ID,
    TRUE                                          AS TRANSCRIPT_AVAILABLE,
    'jiminny'                                     AS TRANSCRIPT_SOURCE,
    CASE WHEN c.ANYVAN_USER_TEAMNAME ILIKE '%inbound%'  THEN 'inbound'
         WHEN c.ANYVAN_USER_TEAMNAME ILIKE '%outbound%' THEN 'outbound' END AS CALL_DIRECTION,
    c.ANYVAN_USER_TEAMNAME                         AS AGENT_TEAM
FROM cand c
JOIN matched m2 USING (EVENT_ID)
ORDER BY INTERACTION_DATETIME DESC
LIMIT 500
