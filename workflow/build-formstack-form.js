#!/usr/bin/env node
'use strict';

/*
 * Build the AnyVan DSR intake form in Formstack via the v2 API.
 *
 * Creates ONE form with all fields + conditional logic, mirroring dsr-intake-form.html
 * (see docs/formstack-dsr-build.md). Run it against your own Formstack account:
 *
 *   FORMSTACK_TOKEN=<oauth access token> node workflow/build-formstack-form.js
 *
 * Dry run (no token needed — prints the planned structure, makes NO API calls):
 *   node workflow/build-formstack-form.js --dry-run
 *
 * Notes / caveats (this could not be tested against a live account from where it was written):
 *  - Auth is an OAuth2 access token (Authorization: Bearer). Create one in your Formstack
 *    account's app/API settings. The token's account must be the EU/UK-region, UK-PII-approved one.
 *  - The script creates fields in order and attaches conditional `logic` referencing fields
 *    created earlier (controllers first), so no second pass is needed.
 *  - Two details vary by API version / plan — flagged inline with [VERIFY]:
 *      (1) `options` payload shape for choice fields (array of {label,value} used here).
 *      (2) Page breaks: sections are created as headings; set "Start a New Page" on the four
 *          section fields in the builder afterwards (one toggle each) — reliable and quick.
 *  - It only CREATES (no deletes/edits). Re-running makes a new form.
 *  - On any field error it logs the API response and continues, then prints a summary so you
 *    can see exactly what the API accepted/rejected on the first run.
 *  - At the end it prints the FORM ID, public URL, and the field-id -> key map. Paste those
 *    ids into docs/dsr-field-mapping.md and workflow/create.sh.
 */

const BASE = 'https://www.formstack.com/api/v2';
const TOKEN = process.env.FORMSTACK_TOKEN || '';
const DRY_RUN = process.argv.includes('--dry-run') || !TOKEN;

const FORM_NAME = 'AnyVan — Data Subject Request';

// ---- field spec -------------------------------------------------------------
// Each entry: { key, type, label, required?, hidden?, options?, description?, showIf? }
// showIf: { any?: [[key, optionValue], ...], all?: [...] }  -> becomes Formstack `logic`.
// Controllers (requester_type, business_type, request_type, sar_data_types) come before dependents.

const REQUESTER = { CUST: 'Customer', TP: 'Transport Partner', TP3: 'Authorised Third Party' };
const BIZ = { SOLE: 'Sole Trader', LTD: 'Limited Company or Partnership' };
const REQ = {
  SAR: 'Access My Data (SAR)', DEL: 'Delete My Data', RECT: 'Correct My Data',
  MKT: 'Marketing Opt-Out', PORT: 'Data Portability',
};
const SAR_CATS = ['Booking & account details', 'Call recordings', 'Chat transcripts',
  'Email correspondence', 'Payment & transaction records', 'All personal data held'];

const FIELDS = [
  { key: 'sec_requester', type: 'section', label: 'Who is making this request?' },
  { key: 'requester_type', type: 'radio', label: 'Requester type', required: 1,
    options: [REQUESTER.CUST, REQUESTER.TP, REQUESTER.TP3] },

  { key: 'sec_details', type: 'section', label: 'Your Details',
    description: 'We need this to verify your identity and locate your data. Fields marked * are required.' },
  { key: 'full_name', type: 'text', label: 'Full name (of the data subject)', required: 1 },
  { key: 'email', type: 'email', label: 'Email address', required: 1 },
  { key: 'phone', type: 'phone', label: 'Phone number', required: 1 },
  { key: 'alt_phone', type: 'phone', label: 'Alternative phone number' },
  { key: 'booking_reference', type: 'text', label: 'AnyVan booking reference (if any)' },

  { key: 'business_type', type: 'radio', label: 'Business type', required: 1,
    options: [BIZ.SOLE, BIZ.LTD], showIf: { any: [['requester_type', REQUESTER.TP]] } },
  { key: 'trading_name', type: 'text', label: 'Trading name (optional)',
    showIf: { any: [['business_type', BIZ.SOLE]] } },
  { key: 'company_name', type: 'text', label: 'Registered company / partnership name', required: 1,
    showIf: { any: [['business_type', BIZ.LTD]] } },
  { key: 'tp_username', type: 'text', label: 'Transport Partner username (optional)',
    showIf: { any: [['requester_type', REQUESTER.TP]] } },

  { key: 'third_party_auth', type: 'textarea', label: 'Authorisation details', required: 1,
    description: 'Your relationship to the data subject and basis for authorisation.',
    showIf: { any: [['requester_type', REQUESTER.TP3]] } },
  { key: 'auth_file', type: 'file', label: 'Proof of authorisation (PDF/JPG/PNG)', required: 1,
    showIf: { any: [['requester_type', REQUESTER.TP3]] } },

  { key: 'account_holder', type: 'checkbox', label: 'Account-holder confirmation', required: 1,
    options: ['I confirm I am the account holder / authorised to make this request'],
    showIf: { any: [['requester_type', REQUESTER.CUST], ['requester_type', REQUESTER.TP]] } },

  { key: 'sec_request', type: 'section', label: 'Your Request' },
  { key: 'request_type', type: 'radio', label: 'What would you like us to do?', required: 1,
    options: [REQ.SAR, REQ.DEL, REQ.RECT, REQ.MKT, REQ.PORT] },

  { key: 'sar_data_types', type: 'checkbox', label: 'What data would you like to access?', required: 1,
    options: SAR_CATS, showIf: { any: [['request_type', REQ.SAR]] } },
  { key: 'call_details', type: 'textarea', label: 'Call recording details',
    description: 'One call per line: date, approx time, and the number used. We need this to locate recordings.',
    showIf: { any: [['sar_data_types', 'Call recordings']] } },
  { key: 'chat_from', type: 'datetime', label: 'Chat transcripts — from date',
    showIf: { any: [['sar_data_types', 'Chat transcripts']] } },
  { key: 'chat_to', type: 'datetime', label: 'Chat transcripts — to date',
    showIf: { any: [['sar_data_types', 'Chat transcripts']] } },
  { key: 'chat_channels', type: 'checkbox', label: 'Chat channels',
    options: ['WhatsApp', 'Live Chat (website)', 'Both / unsure'],
    showIf: { any: [['sar_data_types', 'Chat transcripts']] } },
  { key: 'all_data_from', type: 'datetime', label: 'All-data — earliest interaction', required: 1,
    showIf: { any: [['sar_data_types', 'All personal data held']] } },
  { key: 'all_data_to', type: 'datetime', label: 'All-data — most recent interaction', required: 1,
    showIf: { any: [['sar_data_types', 'All personal data held']] } },
  { key: 'all_data_reason', type: 'textarea', label: 'Reason for requesting all data held', required: 1,
    description: 'Helps us locate all relevant records. Full requests may take the full calendar month.',
    showIf: { any: [['sar_data_types', 'All personal data held']] } },

  { key: 'deletion_scopes', type: 'checkbox', label: 'What data would you like deleted?', required: 1,
    options: ['Full account and all associated data', 'Booking history only', 'Call recordings only',
      'Chat transcripts only', 'Marketing/mailing list data only'],
    showIf: { any: [['request_type', REQ.DEL]] } },

  { key: 'rectification_fields', type: 'checkbox', label: 'Which data needs correcting?', required: 1,
    options: ['Name', 'Email address', 'Phone number', 'Address', 'Other'],
    showIf: { any: [['request_type', REQ.RECT]] } },
  { key: 'rectification_details', type: 'textarea', label: 'Please provide the correct information', required: 1,
    showIf: { any: [['request_type', REQ.RECT]] } },

  { key: 'additional_info', type: 'textarea', label: 'Additional information (optional)' },

  { key: 'sec_declaration', type: 'section', label: 'Review & Declaration' },
  { key: 'declaration', type: 'checkbox', label: 'Declaration', required: 1,
    options: ['I declare the information is accurate, I am the data subject or duly authorised, and I understand my identity will be verified and the request handled within one calendar month (UK GDPR Art. 12(3)).'] },

  { key: 'source', type: 'text', label: 'source', hidden: 1 },
  { key: 'agent', type: 'text', label: 'agent', hidden: 1 },
];

// ---- API plumbing -----------------------------------------------------------
async function api(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = text; }
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text}`);
  return json;
}

function toOptions(values) {
  // [VERIFY] Formstack choice-field option payload. Array of {label,value} used here.
  return values.map((v) => ({ label: v, value: v }));
}

function buildLogic(showIf, idByKey) {
  if (!showIf) return undefined;
  const mode = showIf.all ? 'all' : 'any';
  const checks = (showIf.all || showIf.any).map(([key, option]) => {
    const field = idByKey[key];
    if (!field) throw new Error(`logic references not-yet-created field "${key}"`);
    return { field: String(field), condition: 'equals', option };
  });
  return { action: 'show', conditional: mode, checks };
}

function payloadFor(f, idByKey) {
  const p = { field_type: f.type, label: f.label };
  if (f.required) p.required = 1;
  if (f.hidden) p.hidden = 1;
  if (f.description) p.description = f.description;
  if (f.options) p.options = toOptions(f.options);
  const logic = buildLogic(f.showIf, idByKey);
  if (logic) p.logic = logic;
  return p;
}

// ---- run --------------------------------------------------------------------
(async () => {
  console.log(DRY_RUN ? '=== DRY RUN (no API calls) ===\n' : `Creating form on ${BASE} ...\n`);
  const idByKey = {};
  const errors = [];

  let formId = 'DRYRUN-FORM';
  if (!DRY_RUN) {
    const form = await api('POST', '/form.json', { name: FORM_NAME });
    formId = form.id;
    console.log(`Form created: id=${formId}  "${form.name}"`);
  } else {
    console.log(`Would create form: "${FORM_NAME}"`);
  }

  let idSeq = 1000;
  for (const f of FIELDS) {
    let payload;
    try { payload = payloadFor(f, idByKey); }
    catch (e) { errors.push(`${f.key}: ${e.message}`); console.error(`  ! ${f.key}: ${e.message}`); continue; }

    if (DRY_RUN) {
      idByKey[f.key] = ++idSeq; // fake ids so downstream logic resolves in dry run
      const logicStr = payload.logic ? `  logic=show/${payload.logic.conditional}(${payload.logic.checks.map((c) => c.field + '=' + c.option).join(', ')})` : '';
      console.log(`  [${f.type}] ${f.key}  "${f.label}"${f.required ? ' *' : ''}${logicStr}`);
      continue;
    }

    try {
      const created = await api('POST', `/form/${formId}/field.json`, payload);
      idByKey[f.key] = created.id;
      console.log(`  ok  ${f.key} -> field_${created.id} [${f.type}]`);
    } catch (e) {
      errors.push(`${f.key}: ${e.message}`);
      console.error(`  FAIL ${f.key}: ${e.message}`);
    }
  }

  console.log('\n--- field-id map (paste into docs/dsr-field-mapping.md) ---');
  for (const f of FIELDS) console.log(`  ${f.key.padEnd(22)} field_${idByKey[f.key] ?? '???'}`);

  if (!DRY_RUN) {
    console.log(`\nFORM ID: ${formId}`);
    console.log(`Public URL: https://www.formstack.com/forms/${formId}  (check the exact URL in the builder)`);
    console.log(`Admin entry URL: append  ?field${idByKey.source}=admin&field${idByKey.agent}=<adminId>  to prefill the hidden fields`);
  }
  console.log('\nNext:');
  console.log('  1. In the builder, set the four "sec_*" sections to "Start a New Page" for the 4-step layout.');
  console.log('  2. Configure EU/UK data region, retention, reCAPTCHA, theme, confirmation email (docs/formstack-dsr-build.md).');
  console.log('  3. Put FORM ID + field ids into workflow/create.sh and docs/dsr-field-mapping.md.');
  if (errors.length) {
    console.log(`\n${errors.length} field(s) errored — adjust the flagged [VERIFY] payload shapes and re-run:`);
    errors.forEach((e) => console.log('  - ' + e));
    process.exitCode = 1;
  } else {
    console.log('\nAll fields planned/created with no errors.');
  }
})().catch((e) => { console.error('\nFATAL:', e.message); process.exit(1); });
