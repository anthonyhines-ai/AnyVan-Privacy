#!/usr/bin/env node
// Auto-merge customer REPLY tickets back into their original DSR ticket.
//
// Why this exists: the customer confirmation is sent by Formstack, not Freshdesk, so a customer's
// reply arrives with no Freshdesk ticket id to thread on and Freshdesk opens a NEW ticket. This
// script finds those reply tickets and merges each into the original workflow-created ticket.
//
//   Reply ticket subject : "Re: Your AnyVan Privacy Request: Reference DSR-<submissionId>"
//   Original ticket subj : "[UK] <Type> Privacy Data Request | Requester Type: <...> [<submissionId>]"
//   Shared key           : <submissionId>  (digits)
//
// SAFETY (this is a PII queue — a wrong merge mixes two data subjects' data):
//   - DRY-RUN by default. Nothing is merged unless you pass --apply.
//   - A reply is merged ONLY when there is EXACTLY ONE original with the same submissionId
//     AND the original's requester is the SAME contact (requester_id) as the reply.
//   - Operates only within the configured privacy group ids.
//   - Skips closed/merged tickets and anything ambiguous (0 or >1 candidate) — leaving those for
//     a human, optionally tagged.
//
// Run:
//   export FRESHDESK_API_KEY="<agent api key>"
//   node workflow/freshdesk-merge-dsr-replies.mjs            # DRY-RUN: prints what it would do
//   node workflow/freshdesk-merge-dsr-replies.mjs --once ID  # DRY-RUN a single reply ticket id
//   node workflow/freshdesk-merge-dsr-replies.mjs --apply    # actually merge (after you trust the dry-run)
//
// Schedule the --apply form (cron / scheduler) once the dry-run output looks right. A webhook
// handler can import matchAndMerge() instead of scanning.

const DOMAIN = "anyvan.freshdesk.com";
const BASE = `https://${DOMAIN}/api/v2`;
const GROUPS = [31000116264, 31000119185]; // live Privacy + sandbox; tickets outside these are ignored
const APPLY = process.argv.includes("--apply");
const onceIdx = process.argv.indexOf("--once");
const ONCE_ID = onceIdx > -1 ? Number(process.argv[onceIdx + 1]) : null;

const KEY = process.env.FRESHDESK_API_KEY;
if (!KEY) { console.error("Set FRESHDESK_API_KEY (agent API key)."); process.exit(1); }
const AUTH = "Basic " + Buffer.from(`${KEY}:X`).toString("base64");
const H = { Authorization: AUTH, "Content-Type": "application/json" };

const REPLY_RE    = /Reference\s+DSR-(\d+)/i;   // reply ticket -> submissionId
const ORIGINAL_RE = /\[(\d+)\]\s*$/;            // original ticket subject ends with [submissionId]
const isClosedish = (s) => s === 4 || s === 5;  // 4 resolved, 5 closed (merged secondaries close)

async function fd(path, opts = {}) {
  const r = await fetch(BASE + path, { ...opts, headers: { ...H, ...(opts.headers || {}) } });
  const t = await r.text();
  if (!r.ok) throw new Error(`${opts.method || "GET"} ${path} -> HTTP ${r.status} ${t.slice(0, 300)}`);
  return t ? JSON.parse(t) : {};
}

// Pull recent open/pending tickets in the privacy groups (search API: 30/page, up to 10 pages).
async function scanTickets() {
  const q = encodeURIComponent(`"(${GROUPS.map(g => `group_id:${g}`).join(" OR ")}) AND (status:2 OR status:3)"`);
  const all = [];
  for (let page = 1; page <= 10; page++) {
    const { results = [] } = await fd(`/search/tickets?query=${q}&page=${page}`);
    all.push(...results);
    if (results.length < 30) break;
  }
  return all;
}

function partition(tickets) {
  const replies = [], originalsById = new Map();
  for (const t of tickets) {
    if (isClosedish(t.status)) continue;
    const subj = t.subject || "";
    const o = subj.match(ORIGINAL_RE);
    if (o) { originalsById.set(o[1], t); continue; }      // originals end with [id]
    const rp = subj.match(REPLY_RE);
    if (rp) replies.push({ ticket: t, id: rp[1] });        // replies carry "Reference DSR-<id>"
  }
  return { replies, originalsById };
}

function decide(reply, originalsById) {
  const orig = originalsById.get(reply.id);
  if (!orig) return { action: "skip", reason: `no original found for DSR-${reply.id}` };
  if (orig.id === reply.ticket.id) return { action: "skip", reason: "reply resolves to itself" };
  if (orig.requester_id !== reply.ticket.requester_id)
    return { action: "skip", reason: `requester mismatch (reply ${reply.ticket.requester_id} vs original ${orig.requester_id}) — NOT merging` };
  return { action: "merge", primary_id: orig.id, secondary_id: reply.ticket.id };
}

async function doMerge(primary_id, secondary_id, submissionId) {
  const body = {
    primary_id,
    ticket_ids: [secondary_id],
    convert_recepients_to_cc: true, // Freshdesk's spelling; keeps the replier in the loop on the primary
    note_in_primary: { body: `Auto-merged customer reply ticket #${secondary_id} (DSR-${submissionId}).`, private: true },
  };
  return fd(`/tickets/merge`, { method: "PUT", body: JSON.stringify(body) });
}

async function main() {
  let tickets = await scanTickets();
  if (ONCE_ID) tickets = tickets.filter(t => t.id === ONCE_ID || ORIGINAL_RE.test(t.subject || ""));
  const { replies, originalsById } = partition(tickets);
  const scoped = ONCE_ID ? replies.filter(r => r.ticket.id === ONCE_ID) : replies;

  console.log(`${APPLY ? "APPLY" : "DRY-RUN"} | ${scoped.length} reply ticket(s) to assess | ${originalsById.size} original(s) in scope\n`);
  let merged = 0, skipped = 0;
  for (const reply of scoped) {
    const d = decide(reply, originalsById);
    if (d.action === "skip") { console.log(`SKIP  reply #${reply.ticket.id} (DSR-${reply.id}): ${d.reason}`); skipped++; continue; }
    if (!APPLY) { console.log(`WOULD MERGE reply #${d.secondary_id} -> original #${d.primary_id} (DSR-${reply.id})`); merged++; continue; }
    try { await doMerge(d.primary_id, d.secondary_id, reply.id); console.log(`MERGED reply #${d.secondary_id} -> original #${d.primary_id} (DSR-${reply.id})`); merged++; }
    catch (e) { console.log(`ERROR merging #${d.secondary_id}: ${e.message}`); skipped++; }
  }
  console.log(`\nDone. ${APPLY ? "merged" : "would merge"}=${merged} skipped=${skipped}`);
}

main().catch(e => { console.error(e.message); process.exit(1); });
