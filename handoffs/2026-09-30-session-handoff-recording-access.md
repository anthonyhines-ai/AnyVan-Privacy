# Session Handoff — Freshdesk `2264362` call lookup → Interaction Hub recording access

> ℹ️ **INTERNAL — contains no customer personal data.** This handoff references the PII record by path
> (that record carries the CONFIDENTIAL/PII banner); it repeats no customer name, number or IDs itself.

| | |
|---|---|
| **Record type** | Session handoff / continuity note |
| **Date** | 2026-09-30 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Container** | Draft PR #21 → `main` (`anthonyhines-ai/AnyVan-Privacy`) · branch `claude/stoic-mccarthy-r4cmrl` |
| **Spans** | `communication-lookups/` · `retention/` · `interaction-hub/` |

---

## 1. Core context (how it started, where it ended)

Started as: *"we're struggling to find calls for this customer on Freshdesk 2264362 (07867337470)."*
The calls were never missing — they were **fragmented**. Resolving that opened a chain: how retention
affects the audio, where the audio actually lives, whether the Interaction Hub surfaces it, and a
proposed fix. Everything below is on **PR #21** (draft, no CI — validation is human review).

Arc: locate calls → per-call **retention status** → **company-wide** retention gap → correct the store
(Twilio API → **AnyVan proxy → S3**) → verify **current** Hub coverage → **by-CallSid** fix spec →
backlog + Command Centre action.

---

## 2. What was delivered (artefacts)

| File / place | What |
|---|---|
| `communication-lookups/2026-09-16-call-lookup-freshdesk-2264362-07867337470.md` (**PII**) | The customer call record: identity resolution, ~39 call events (2 bookings + 1 quote), full agent-attributed log, per-call **retrieval status**, and the **verification pack** (5 recording SIDs + runnable proxy check). |
| `retention/2026-09-16-call-recording-retention-gap.md` (INTERNAL) | Company-wide sizing of the 3→12-month change: **~2.4M avoidable** / ~9.5M total (connected-leg proxy), caveats, SQL. |
| `interaction-hub/2026-08-26-call-recording-playback-diagnosis.md` | Appended **§7 current-state verification (2026-09-26)** + the transcript-independent access note. |
| `interaction-hub/2026-09-28-recording-by-callsid-route-build-spec.md` | The **fix spec** (Option B) + interim note + **Status: BACKLOG** (B1 route/button, B2 SSO). |
| Command Centre (Artifact `DyCBhQvjWgvyKGTGHqDbfn`) | Action added to the **Actions** inbox (`db` collection `actions`, doc `act-ihub-recording-access`), links to PR #21, priority left for triage. |
| Slack message | **Drafted in chat, not sent** — asks the proxy owner for the by-CallSid route (+ SSO). |

---

## 3. Key findings / decisions

- **Calls exist, fragmented.** Search failed because: number stored **E.164** (match last-10, not `0…`);
  `HARMONISED.PRODUCTION.TWILIO_CALL_TO_LISTING_MAPPING` is **empty** for these; Freshdesk isn't the
  telephony system of record; calls spread across ~10 queues / 3 teams; Flex calls are audio-only.
- **The agent/booking-attributed spine is `MART_SALES_OPS.PRODUCTION.FACT_VOICE_ACTIVITY`** (has
  `LISTING_ID`, agent, queue, talk time), **not** the empty raw mapping table.
- **Retention:** 3-month → **12-month on 5 May 2026**. A purge is irreversible; the extension only saved
  recordings still alive at the switch, so audio survives only for calls **on/after ~5 Feb 2026**.
  Statuses in the record are **policy-derived, not yet verified**.
- **The store is AnyVan's S3, not Twilio.** Audio is served by the proxy
  `twilio-recordings.anyvan.com/recordings/{RecordingSid}` → S3 `anyvan-twilio-recordings`. **Open
  question:** is the 3→12-month rule Twilio-native retention or an **S3 lifecycle policy**? That decides
  what's truly recoverable.
- **Current Hub coverage (verified live):** `interaction_hub_calls` / `interaction_hub_phone_lookup` now
  build a recording link for admin calls from `CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS` (STT, ~153k)
  on `WORKERCALLSID` — but it only covers **transcribed** calls. This customer: **0 of 37 legs** in that
  table → no 🎧 Listen button. The recording is unaffected; it's a link-discovery gap.
- **Interim already exists:** the live Hub shows **🖥️ Twilio Console** and **▶️ Twilio Flex** buttons on
  a call (built from the call ID, no transcript) — anyone with Twilio/Flex access plays/downloads there.
- **The fix (Option B):** proxy route `GET /recordings/by-call/{CallSid}` so the Hub emits a
  Listen/Download link for **every** call, transcript-independent; pair with SSO so no key prompt.

---

## 4. Current state & what's pending (owners)

- **PR #21** — draft into `main`, clean, no CI. → **Ant: review + merge.** ("Done ≠ on `main`.")
- **Twilio verification (Route B)** — 5 recording SIDs in the record §10; run the proxy check with the
  Basic-Auth key. → **Twilio/proxy owner.** Flips statuses from *policy-derived* to *verified*; also
  answers the S3-vs-Twilio retention-enforcement question.
- **The raise (B1/B2)** — Slack message drafted; not sent (no channel given). → **Ant to post; proxy
  owner builds route.** Also logged as the Command Centre action (untriaged).
- **Company-wide number refinement** — parent-SID dedup + reconciliation against the served store.
  (Was queued as a suggested task earlier this session.) → optional.
- **Repo hygiene** — `interaction-hub.html` in the repo is **stale vs the deployed dashboard** (live has
  the Flex/Console/Download buttons the repo copy lacks). → optional sync.
- **Jira** — offered (project **CCAA**); Ant chose Slack. Not raised. → optional.

---

## 5. Reusable gotchas (for the next session)

- Phone match = `RIGHT(REGEXP_REPLACE(num,'[^0-9]',''),10)`; `"FROM"`/`"TO"` are reserved (quote them).
- Recording ≠ transcript ≠ metadata: metadata (warehouse + HubSpot engagement) outlives the audio; a
  HubSpot `hs_call_recording_url` **persists after the file is purged** — a link is not proof.
- Recording retrieval: RecordingSid → `twilio-recordings.anyvan.com/recordings/{RE}` (Basic Auth), or
  resolve from a CallSid via Twilio `…/Calls/{CallSid}/Recordings.json`. **Never** commit the Twilio
  **Account SID** (`AC…`) — push protection blocks it; RE/CA SIDs are fine.
- Hub queries: `interaction_hub_calls`, `interaction_hub_phone_lookup` (7-day vs 12-month `:days`).

---

## 6. Tone / working style (Ant)

British English, concise, direct. Tables over prose. Systems over improvisation, evidence over
narrative — verify against **live** systems, don't trust a month-old doc. Challenge assumptions; own
corrections plainly. Keep secrets out of git and chat.

---

## 7. References

- PR: https://github.com/anthonyhines-ai/AnyVan-Privacy/pull/21
- Customer identity, call log, recording SIDs, verification snippet → the `communication-lookups/…`
  record (§3, §6, §10). Command Centre artifact: `DyCBhQvjWgvyKGTGHqDbfn`.
</content>
