#!/usr/bin/env node
// Create the "Form Submitted Event" webhook on the [UK] Privacy DSR Formstack form (6559077)
// so a submission publishes FORMSTACK_FORM_SUBMITTED to the AnyVan event bus
// (https://events.anyvan.com/v1/formstack/form-submitted) — the event the
// "[UK] Privacy Submission Workflow" consumes to raise the Freshdesk ticket.
//
// Mirrors the live "Damage Claim - UK - Formstack" webhook (form 6200752). The HMAC signing
// secret that events.anyvan.com verifies is COPIED FROM THE DAMAGE WEBHOOK AT RUNTIME and never
// printed or committed. This assumes events.anyvan.com verifies with ONE shared secret across
// AnyVan Formstack webhooks (consistent with the generic "publish every submission, filter by
// formId in the workflow" design). If instead it holds a per-form secret, the platform team
// (errorEmails owner on the Damage hook: tom.michaelis@anyvan.com) must register form 6559077 —
// you'll know from the verification step below.
//
// Run:
//   export FORMSTACK_TOKEN="<fresh fs_pat_… PAT>"
//   node workflow/create-webhook.mjs            # creates (idempotent: aborts if one exists)
//   node workflow/create-webhook.mjs --verify   # just lists the Privacy form's webhooks
//
// Idempotent: aborts if the Privacy form already has any webhook.

const TOKEN = process.env.FORMSTACK_TOKEN;
if (!TOKEN) { console.error("Set FORMSTACK_TOKEN (fresh fs_pat_… PAT)."); process.exit(1); }

const BASE = "https://www.formstack.com/api/v2025";
const H = { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json", Accept: "application/json" };
const PRIVACY = "6559077";
const DAMAGE  = "6200752";
const redact = (w) => ({ ...w, hmacSecret: w.hmacSecret ? `[present, len ${w.hmacSecret.length}]` : "(empty)" });

async function getHooks(formId) {
  const r = await fetch(`${BASE}/forms/${formId}/webhooks`, { headers: H });
  if (!r.ok) throw new Error(`GET webhooks ${formId}: HTTP ${r.status} ${await r.text()}`);
  return (await r.json()).webhooks || [];
}

if (process.argv.includes("--verify")) {
  console.log(JSON.stringify((await getHooks(PRIVACY)).map(redact), null, 2));
  process.exit(0);
}

// 1) idempotency guard
const existing = await getHooks(PRIVACY);
if (existing.length) {
  console.log("ABORT — Privacy form already has a webhook:");
  console.log(JSON.stringify(existing.map(redact), null, 2));
  process.exit(0);
}

// 2) copy the signing secret from the Damage webhook (in-memory only)
const dmg = (await getHooks(DAMAGE))[0];
if (!dmg || !dmg.hmacSecret) throw new Error("Could not read the Damage webhook hmacSecret to mirror.");

// 3) minimal valid payload (GET display labels like fileTransferType/postDataFieldKeys are NOT
//    accepted on POST; Formstack defaults them. events.anyvan.com only needs url + JSON + the
//    HMAC signature + the standard uniqueId/formId submission metadata, which is always sent.)
const payload = {
  name: "Form Submitted Event",
  url: "https://events.anyvan.com/v1/formstack/form-submitted",
  contentType: "JSON",
  hmacSecret: dmg.hmacSecret,          // copied at runtime, never logged
  errorEmails: "anthony.hines@anyvan.com",
};

const r = await fetch(`${BASE}/forms/${PRIVACY}/webhooks`, { method: "POST", headers: H, body: JSON.stringify(payload) });
const t = await r.text();
if (!r.ok) { console.error(`POST failed: HTTP ${r.status}\n${t}`); process.exit(1); }
console.log("Created webhook:");
console.log(JSON.stringify(redact(JSON.parse(t)), null, 2));
console.log("\nVERIFY: send ONE test submission, then check workflow executions. An execution means");
console.log("events.anyvan.com accepted the signature. No execution => HMAC/registration issue =>");
console.log("ping the platform team (tom.michaelis@anyvan.com) to register form 6559077.");
