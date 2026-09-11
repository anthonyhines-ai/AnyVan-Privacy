------------------------------------------------------------------------------
-- interaction_hub_email_body.sql
--
-- Source-of-truth SQL for the AV Dashboards saved query
-- `interaction_hub_email_body` (register via the AV_Dashboards MCP).
--
-- WHY: the Interaction Hub "Emails" tab is metadata-only ("no bodies"). This
-- query fetches the AUTHORITATIVE rendered HTML of ONE transactional email so the
-- hub can PREVIEW exactly what the customer received (sandboxed iframe on
-- row-expand). Kept out of the list query so 20-30 KB HTML blobs never bloat the
-- timeline payload.
--
-- KEY: MESSAGE_ID — the Emails tab already returns this as the row's
-- INTERACTION_ID for Transactional emails (interaction_hub_emails: txn CTE selects
-- `m.MESSAGE_ID AS INTERACTION_ID`). So the preview is an exact 1-row lookup, no
-- timestamp/tolerance matching needed.
--
-- COVERAGE (be honest in the UI): rendered HTML exists for SOME sends only. Even
-- post-2026-05-19, not every dispatched email has a stored body (e.g. reminder
-- emails are stored; booking-confirmation / driver-assigned often are NOT). When
-- this returns 0 rows, fall back to the admin listing-communications /view page.
-- MARKETING emails (EVENTS_EMAIL) have NO body at all — this query is transactional
-- only; a marketing row shows metadata + a link to the campaign, never a fake body.
--
-- SAFETY: MESSAGE is third-party-authored HTML — render in a sandboxed iframe
-- (sandbox, no allow-scripts, no allow-top-navigation); never inject into the DOM.
--
-- Param: :message_id  (the row's INTERACTION_ID for a Transactional email)
--
-- Validated read-only against PRODUCTION (2026-09-10): a live MESSAGE_ID returned
-- exactly 1 row — correct subject + ~30 KB rendered HTML body.
------------------------------------------------------------------------------

SELECT
    m.MESSAGE_ID,
    m.RENDERED_SUBJECT,
    m.TEMPLATE_KEY,
    m.RESOLVED_USER_EMAIL                                       AS recipient,
    CONVERT_TIMEZONE('Europe/London', m.EVENT_TIMESTAMP)::TIMESTAMP_NTZ AS sent_at_bst,
    m.MESSAGE                                                   AS rendered_html   -- render in a SANDBOXED iframe
FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE m
WHERE m.CHANNEL = 'EMAIL'
  AND m.MESSAGE_ID = :message_id
LIMIT 1;
