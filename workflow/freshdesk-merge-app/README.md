# DSR reply auto-merge — Freshworks serverless app

A custom Freshdesk app that merges customer **reply** tickets back into their original DSR ticket,
running on Freshworks' serverless platform (no external host). This is the "built on Freshdesk"
version of `workflow/freshdesk-merge-dsr-replies.mjs`.

## Why an app, not a rule
Freshdesk automations (Ticket Creation / Updates / Hourly) have **no merge action** — merge is only
available via the API. A serverless app's `onTicketCreate` handler can call that API, so the whole
thing lives inside Freshdesk.

## What it does
On every new ticket:
1. If the subject matches `Re: Your AnyVan Privacy Request: Reference DSR-<id>` → it's a reply.
2. Find open/pending tickets in the privacy groups whose subject ends `[<id>]` (the original).
3. Merge the reply into the original **only if** exactly one original matches **and** it has the
   **same requester** (`requester_id`). Otherwise do nothing (left for a human).

The id + requester double-match is the safety guard: it can never merge two different data subjects.

## Files
- `manifest.json` — event registration (reconcile `platform-version`/`engines` with your FDK, below)
- `config/iparams.json` — install-time settings: domain, agent API key (secure), privacy group IDs
- `config/requests.json` — **request templates** for the two Freshdesk API calls (search + merge).
  Current Freshworks platform requires outbound calls to go through templates invoked with
  `$request.invokeTemplate()` — the old direct `$request.get/put` + whitelisted-domains style is
  deprecated (end-of-life Sept 2023), which is why there is no `whitelisted-domains` in the manifest.
- `server/server.js` — the `onTicketCreateHandler`

The secure API key is referenced **only inside `requests.json`** (`<%= encode(iparam.freshdesk_api_key + ':X') %>`),
never read in `server.js` — so the secret never touches app code.

## Prerequisites
- Node.js (the version your installed FDK requires — current FDK needs a recent Node; `fdk version` confirms) and the Freshworks CLI (`brew tap freshworks-developers/homebrew-tap && brew install fdk` on macOS).
- An agent **API key** with permission to merge tickets (use a dedicated service agent; this is also one of the keys on the rotation list).
- Admin access to install a custom app in Freshdesk.

## Build & deploy

1. **Scaffold with the current FDK** (so the manifest matches your installed CLI version):
   ```bash
   fdk create --products freshdesk --template serverless-starter-template dsr-merge-app
   cd dsr-merge-app
   ```
2. **Drop in these files**, overwriting the scaffold:
   - replace `server/server.js` with the one here
   - replace `config/iparams.json` with the one here
   - add `config/requests.json` from here (the request templates)
   - in the generated `manifest.json`, add the `onTicketCreate` event handler under
     `product.freshdesk` (see this folder's `manifest.json`), and keep the `platform-version` /
     `engines` the scaffold gave you rather than copying ours verbatim. No `whitelisted-domains` is
     needed — the request templates define the host.
3. **Test locally** against the event:
   ```bash
   fdk run
   # in another shell, simulate a reply-ticket creation:
   # open http://localhost:10001/web/test  ->  choose onTicketCreate  ->  set the ticket subject to
   #   "Re: Your AnyVan Privacy Request: Reference DSR-1502887183" and a group_id in your list,
   # and confirm the logs show the match/merge decision. Point it at a TEST ticket pair first.
   ```
4. **Validate & pack**:
   ```bash
   fdk validate
   fdk pack
   ```
5. **Upload** `dist/*.zip` as a **Custom App** in Freshdesk (Admin → Apps → Manage/Get more apps →
   Custom Apps → Upload) and enter the install settings (domain, API key, group IDs).

## Verify
Create a test DSR submission **as yourself** so the original ticket's requester is your mailbox, then
reply from that same mailbox. The reply ticket should merge into the original within moments. Check
the original's activity for the private "Auto-merged customer reply…" note.

> **Testing note:** replying from a different mailbox than the original ticket's requester will
> correctly **not** merge (the requester guard). That's expected, not a fault.

## Auth detail to confirm on first `fdk run`
Freshdesk Basic auth is `base64("<api-key>:X")`. The template uses
`encode(iparam.freshdesk_api_key + ':X')`. If your FDK version rejects the inline `+ ':X'`
concatenation, the fallback is to store the iparam value already as `<api-key>:X` and change the
template to `encode(iparam.freshdesk_api_key)`. Confirm the search call returns JSON (not a 401/HTML)
during `fdk run` before packing.

## Hardening (optional)
- The API key lives only in the request template via the secure iparam — never in `server.js` (done).
- Use a dedicated service agent for the API key so merges are attributable and the key is revocable.

## Relationship to the script
`workflow/freshdesk-merge-dsr-replies.mjs` is the same logic as a standalone scan (run on a schedule).
Use **one** of them, not both. This app is the event-driven, Freshdesk-hosted option.
