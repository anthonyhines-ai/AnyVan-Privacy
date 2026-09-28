# Interaction Hub — Recording access by CallSid (build spec)

> ℹ️ **INTERNAL — contains no customer personal data.** Implementation spec for the recording proxy and
> the Interaction Hub. No customer numbers, RecordingSids, or the proxy/Twilio credentials appear here.

| | |
|---|---|
| **Record type** | Build spec / handoff (dashboard + proxy service) |
| **Date created** | 2026-09-28 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Surface** | Interaction Hub + recording proxy `twilio-recordings.anyvan.com` |
| **Context** | Follows `interaction-hub/2026-08-26-call-recording-playback-diagnosis.md` (§3 Option B) |

---

## TL;DR (plain)

Goal: **every call in the Interaction Hub gets a 🎧 Listen / ⬇️ Download button — with or without a
transcript.** Today the button only appears when a transcript exists, because that's the only place the
hub finds the recording's ID. The fix is to let the proxy find the recording from the **CallSid** (which
every call already has), so a transcript is no longer needed.

It's two small pieces:
1. **The proxy service** gains one route (owner: the proxy/telephony service owner — *not* something I
   can deploy from here).
2. **The hub** points its button at that route (a one-line query change — I can deploy this once the
   route is live).

Agents authenticate **once** to hear a recording (today a username/password prompt; recommended: make it
the dashboard login so there's nothing to type — see §5).

---

## 1. Why the button is missing today

The hub builds a recording link only when it can find a `RecordingSid`. Right now that comes from the
transcript table (`CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS`). Human-agent calls that were never
transcribed have no row there → no `RecordingSid` → **no button** — even though the audio exists.

Every call, transcribed or not, **does** have a `CallSid` (`WORKERCALLSID`) in the warehouse, and the
recording exists in S3 regardless of transcription. So resolve by CallSid and the transcript dependency
disappears.

---

## 2. The route (proxy service — owner to build)

```
GET https://twilio-recordings.anyvan.com/recordings/by-call/{CallSid}
```

- **Auth:** same as the existing `/recordings/{RecordingSid}` route (§5).
- **Behaviour:** look the call up via Twilio
  `GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json`, then:
  - **1 recording** → `302` to its media (exactly as `/recordings/{RecordingSid}` does today).
  - **Several** (a transferred call has one per leg) → return a small JSON list of
    `/recordings/{RecordingSid}` links (one per leg) so the hub can show a player each.
  - **None / purged** → `404`.
- It reuses the existing media path underneath — it's a thin "resolve SID from CallSid, then redirect"
  wrapper. Small change.

---

## 3. Hub query change (I can deploy once the route is live)

In **both** `interaction_hub_calls` and `interaction_hub_phone_lookup`, the admin branch's recording
link becomes CallSid-based instead of transcript-based:

```sql
'https://twilio-recordings.anyvan.com/recordings/by-call/' || COALESCE(WORKERCALLSID, TASKSID)
    AS RECORDING_URL
```

Keep the existing `CALL_TRANSCRIPT_CALLS` join **only** for `TRANSCRIPT_AVAILABLE` / the transcript
viewer — the recording no longer depends on it. (The Calls tab is a 7-day window; the phone-lookup
already spans 12 months, which is the path for older calls.)

---

## 4. Hub UI

The renderer already shows **🎧 Listen** whenever `RECORDING_URL` is present (opens in a new tab). Add a
**⬇️ Download** link (same URL) and, for a transferred call, one player/link per leg. Minimal HTML.

---

## 5. Auth / UX — the "username & password" question

- **Today:** the proxy is protected by **HTTP Basic Auth** — i.e. a username + password, which is a
  Twilio **API key** (SID = username, secret = password). The browser prompts for it **once** and caches
  it for the session, so an agent enters it a single time and then every recording plays/downloads for
  the rest of that session. The key is **not** embedded in the page.
- **Recommended (the real win):** put the proxy behind the **dashboard's existing SSO / login session**
  (or issue short-lived signed URLs) so agents just click and it plays — **nothing to type, and no
  Twilio key in anyone's hands.** Handing the raw key to every reviewer is a security smell (flagged in
  the 2026-08-26 diagnosis §4). Recommended, not required, to make playback work.

---

## 6. Sequencing & owners

1. **Proxy owner** ships the `/recordings/by-call/{CallSid}` route (and ideally the SSO in §5).
2. **Then** the two hub queries flip to the by-call URL + the Download button goes in (I can do this via
   the AV Dashboards MCP).

Do **not** flip the queries first — the buttons would `404` until the route exists.

---

## 7. Retention caveat

A recording link only resolves if the media still exists in S3/Twilio. Recordings purged under the old
3-month policy (calls before ~5 Feb 2026) will `404` even with a button present — the same retention
question tracked in `retention/2026-09-16-call-recording-retention-gap.md`. The button gives *access*; it
does not resurrect purged audio.

---

## 8. Governance notes

- No customer PII, RecordingSids, or credentials in this spec.
- The proxy serves customer call recordings (PII); access must stay behind auth and be logged, and the
  Twilio API key must never be embedded in the hub HTML or committed anywhere (rotate if exposed).
