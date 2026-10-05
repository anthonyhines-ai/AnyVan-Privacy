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
- `manifest.json` — event registration + whitelisted domain (reconcile with your FDK version, below)
- `config/iparams.json` — install-time settings: domain, agent API key (secure), privacy group IDs
- `server/server.js` — the `onTicketCreateHandler`

## Prerequisites
- Node.js 18+ and the Freshworks CLI: `npm install -g @freshworks/cli`
- An agent **API key** with permission to merge tickets (use a service agent; rotate the shared key).
- Admin access to install a custom app in Freshdesk.

## Build & deploy

1. **Scaffold with the current FDK** (so the manifest matches your installed CLI version):
   ```bash
   fdk create --products freshdesk --template your_first_serverless_app dsr-merge-app
   cd dsr-merge-app
   ```
2. **Drop in these files**, overwriting the scaffold:
   - replace `server/server.js` with the one here
   - replace `config/iparams.json` with the one here
   - in the generated `manifest.json`, add the `onTicketCreate` event handler and the
     `whitelisted-domains` entry for `https://<your-domain>.freshdesk.com` (see this folder's
     `manifest.json` for the exact blocks — keep the `platform-version`/`engines` the scaffold gave
     you rather than copying ours verbatim).
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

## Hardening (optional)
- Store the API key only via the secure iparam (done) — never in code.
- Prefer Freshworks **Request Method templates** over inline `$request` with the key, if your
  security review requires it.
- Use a dedicated service agent for the API key so merges are attributable and the key is revocable.

## Relationship to the script
`workflow/freshdesk-merge-dsr-replies.mjs` is the same logic as a standalone scan (run on a schedule).
Use **one** of them, not both. This app is the event-driven, Freshdesk-hosted option.
