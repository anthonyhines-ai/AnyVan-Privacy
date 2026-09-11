------------------------------------------------------------------------------
-- interaction_hub_notifications.sql
--
-- Source-of-truth SQL for the AV Dashboards saved query
-- `interaction_hub_notifications` (register/update via the AV_Dashboards MCP;
-- do NOT paste SQL into the dashboard HTML).
--
-- WHY THIS EXISTS
-- The Interaction Hub currently shows ZERO of the transactional emails / SMS /
-- WhatsApp templates that AnyVan SENDS to a customer. Its existing queries only
-- cover Twilio agent/AI CONVERSATIONS (calls, live chat, inbound WhatsApp). The
-- booking-confirmation / reminder / driver-assigned / feedback comms live in a
-- different table it never touches — so a customer with only automated comms
-- shows "0 interactions". This query surfaces those "notification" sends.
--
-- SPINE TABLE: HARMONISED.PRODUCTION.LISTING_COMMUNICATION  (one row per send)
--   * Keyed by LISTING_ID. Authoritative "what was DISPATCHED" log.
--   * CHANNEL ∈ email | sms | whats-app ;  TARGET ∈ customer | provider | address
--   * STATUS is a NUMBER dispatch code (2 = dispatched) — NOT a delivery/read
--     receipt. Label it "dispatched", never "delivered".
--   * SMS body is AUTHORITATIVE here: GET(TRY_PARSE_JSON(TOKENS),'message') — use GET(), NOT the
--     Snowflake path TOKENS:message: the AV Dashboards bind-scanner misreads ":message" as a bind param.
--
-- MATCH KEY: the resolved customer's LISTING_ID(s), from the identity resolver.
--   :listing_ids is a COMMA-SEPARATED string; split server-side with
--   SPLIT_TO_TABLE (single- and multi-id both validated to bind correctly).
--
-- CONTENT (metadata != content):
--   * SMS  body  -> inline here (TOKENS.message).
--   * Email body -> NOT here; fetched on row-expand by interaction_hub_email_body
--                   (rendered HTML exists only for SOME sends; see that file).
--   * WhatsApp body -> in Twilio (TWILIO_MESSAGE), via the conversation path.
--   * admin_view_url below is the authoritative render for ANY channel/age.
--
-- VALIDATED read-only against PRODUCTION (2026-09-10) with a live single-listing
-- UK customer: returned 7 customer emails, 2 SMS, 1 WhatsApp; provider-targeted
-- rows correctly excluded; SMS bodies parsed cleanly from TOKENS.
------------------------------------------------------------------------------

SELECT
    lc.LISTING_COMMUNICATION_ID                                    AS interaction_id,
    lc.LISTING_ID,
    'notification'                                                 AS source,          -- vs 'conversation'
    CASE lc.CHANNEL WHEN 'whats-app' THEN 'whatsapp'
                    ELSE lc.CHANNEL END                            AS channel,         -- email | sms | whatsapp
    lc.TYPE                                                        AS template_type,   -- e.g. driver-assigned
    lc.CREATED_AT                                                  AS sent_at,         -- UTC (TIMESTAMP_TZ); display BST
    CASE WHEN lc.STATUS = 2 THEN 'dispatched'
         ELSE 'status ' || lc.STATUS::string END                  AS dispatch_status, -- NOT delivery/read state
    lc.TARGET,
    GET(TRY_PARSE_JSON(lc.TOKENS), 'message')::string             AS sms_body,        -- SMS body; use GET() not TOKENS:message (see note)
    'https://www.anyvan.com/administer/instant-listings/' || lc.LISTING_ID::string
        || '/listing-communications/' || lc.LISTING_COMMUNICATION_ID::string || '/view'
                                                                   AS admin_view_url   -- authoritative render, all channels
FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
WHERE lc.LISTING_ID IN (
        SELECT TRIM(value)::number
        FROM TABLE(SPLIT_TO_TABLE(:listing_ids, ','))
      )
  AND lc.TARGET = 'customer'     -- customer-facing only (drop provider / address comms)
  AND lc.DELETED_ROW = FALSE
ORDER BY lc.CREATED_AT DESC;
