#!/usr/bin/env node
'use strict';

/*
 * Build the AnyVan DSR intake form in Formstack via the V2025 API.
 *
 * Creates ONE form with all fields + conditional logic, mirroring dsr-intake-form.html
 * (see docs/formstack-dsr-build.md). Run against your own Formstack account:
 *
 *   FORMSTACK_TOKEN=<fs_pat_...> node workflow/build-formstack-form.js
 *
 * Dry run (no token, no API calls — prints the planned structure):
 *   node workflow/build-formstack-form.js --dry-run
 *
 * Auth: a Formstack Personal Access Token (fs_pat_...) sent as `Authorization: Bearer`.
 * API: V2025, base https://www.formstack.com/api/v2025 (endpoints/shapes confirmed against a
 * live AnyVan form). Only CREATES a form + fields (no deletes). Prints the field-id map at the
 * end for docs/dsr-field-mapping.md. On a field error it logs the response and continues.
 *
 * To remove a form created by mistake:
 *   FORMSTACK_TOKEN=... node workflow/build-formstack-form.js --delete <formId>
 */

const BASE = 'https://www.formstack.com/api/v2025';
const TOKEN = process.env.FORMSTACK_TOKEN || '';
const DRY_RUN = process.argv.includes('--dry-run') || !TOKEN;
const DELETE_ID = process.argv.includes('--delete') ? process.argv[process.argv.indexOf('--delete') + 1] : null;
const FORM_NAME = 'AnyVan — Data Subject Request (DSR)';

// ---- vocab ------------------------------------------------------------------
const REQUESTER = { CUST: 'Customer', TP: 'Transport Partner', TP3: 'Authorised Third Party' };
const BIZ = { SOLE: 'Sole Trader', LTD: 'Limited Company or Partnership' };
const REQ = {
  SAR: 'Access My Data (SAR)', DEL: 'Delete My Data', RECT: 'Correct My Data',
  MKT: 'Marketing Opt-Out', PORT: 'Data Portability',
};
// NB: "Payment & transaction records" was removed on the live form (5 categories).
const SAR_CATS = ['Booking & account details', 'Call recordings', 'Chat transcripts',
  'Email correspondence', 'All personal data held'];

// showIf: { any:[[key,value],...] } -> OR ; { all:[...] } -> AND
const FIELDS = [
  { key: 'sec_requester', type: 'section', label: 'Who is making this request?' },
  { key: 'requester_type', type: 'radio', label: 'Requester type', required: true,
    options: [REQUESTER.CUST, REQUESTER.TP, REQUESTER.TP3] },

  { key: 'sec_details', type: 'section', label: 'Your Details', newPage: true,
    hint: 'We need this to verify your identity and locate your data. Fields marked * are required.' },
  { key: 'full_name', type: 'text', label: 'Full name (of the data subject)', required: true },
  { key: 'email', type: 'email', label: 'Email address', required: true },
  { key: 'phone', type: 'text', label: 'Phone number', required: true, hint: 'Include country code, e.g. +44 7…' },
  { key: 'alt_phone', type: 'text', label: 'Alternative phone number' },
  { key: 'booking_reference', type: 'text', label: 'AnyVan booking reference (if any)', hint: 'e.g. AV1234567' },

  { key: 'business_type', type: 'radio', label: 'Business type', required: true,
    options: [BIZ.SOLE, BIZ.LTD], showIf: { any: [['requester_type', REQUESTER.TP]] } },
  { key: 'trading_name', type: 'text', label: 'Trading name (optional)',
    showIf: { any: [['business_type', BIZ.SOLE]] } },
  { key: 'company_name', type: 'text', label: 'Registered company / partnership name', required: true,
    showIf: { any: [['business_type', BIZ.LTD]] } },
  { key: 'tp_username', type: 'text', label: 'Transport Partner username (optional)',
    showIf: { any: [['requester_type', REQUESTER.TP]] } },

  { key: 'third_party_auth', type: 'textarea', label: 'Authorisation details', required: true,
    hint: 'Your relationship to the data subject and basis for authorisation.',
    showIf: { any: [['requester_type', REQUESTER.TP3]] } },
  { key: 'auth_file', type: 'file', label: 'Proof of authorisation (PDF/JPG/PNG)', required: true,
    showIf: { any: [['requester_type', REQUESTER.TP3]] } },

  { key: 'account_holder', type: 'checkbox', label: 'Account-holder confirmation', required: true,
    options: ['I confirm I am the account holder / authorised to make this request'],
    showIf: { any: [['requester_type', REQUESTER.CUST], ['requester_type', REQUESTER.TP]] } },

  { key: 'sec_request', type: 'section', label: 'Your Request', newPage: true },
  { key: 'request_type', type: 'radio', label: 'What would you like us to do?', required: true,
    options: [REQ.SAR, REQ.DEL, REQ.RECT, REQ.MKT, REQ.PORT] },

  { key: 'sar_data_types', type: 'checkbox', label: 'What data would you like to access?', required: true,
    options: SAR_CATS, showIf: { any: [['request_type', REQ.SAR]] } },
  { key: 'call_from', type: 'datetime', label: 'Call Recordings - From Date',
    showIf: { any: [['sar_data_types', 'Call recordings']] } },
  { key: 'call_to', type: 'datetime', label: 'Call Recordings - To Date',
    showIf: { any: [['sar_data_types', 'Call recordings']] } },
  { key: 'chat_from', type: 'datetime', label: 'Chat transcripts — from date',
    showIf: { any: [['sar_data_types', 'Chat transcripts']] } },
  { key: 'chat_to', type: 'datetime', label: 'Chat transcripts — to date',
    showIf: { any: [['sar_data_types', 'Chat transcripts']] } },
  { key: 'chat_channels', type: 'checkbox', label: 'Chat channels',
    options: ['WhatsApp', 'Live Chat (website)', 'Both / unsure'],
    showIf: { any: [['sar_data_types', 'Chat transcripts']] } },
  { key: 'all_data_from', type: 'datetime', label: 'All-data — earliest interaction', required: true,
    showIf: { any: [['sar_data_types', 'All personal data held']] } },
  { key: 'all_data_to', type: 'datetime', label: 'All-data — most recent interaction', required: true,
    showIf: { any: [['sar_data_types', 'All personal data held']] } },
  { key: 'all_data_reason', type: 'textarea', label: 'Reason for requesting all data held', required: true,
    hint: 'Helps us locate all relevant records. Full requests may take the full calendar month.',
    showIf: { any: [['sar_data_types', 'All personal data held']] } },

  { key: 'deletion_scopes', type: 'checkbox', label: 'What data would you like deleted?', required: true,
    hint: 'Some data may be retained where AnyVan has a legal obligation (finance, fraud, active disputes).',
    options: ['Full account and all associated data', 'Booking history only', 'Call recordings only',
      'Chat transcripts only', 'Marketing/mailing list data only'],
    showIf: { any: [['request_type', REQ.DEL]] } },

  { key: 'rectification_fields', type: 'checkbox', label: 'Which data needs correcting?', required: true,
    options: ['Name', 'Email address', 'Phone number', 'Address', 'Other'],
    showIf: { any: [['request_type', REQ.RECT]] } },
  { key: 'rectification_details', type: 'textarea', label: 'Please provide the correct information', required: true,
    showIf: { any: [['request_type', REQ.RECT]] } },

  { key: 'marketing_note', type: 'richtext',
    html: '<p>We will remove you from all AnyVan marketing (email, SMS, push). This does not affect transactional messages about active bookings.</p>',
    showIf: { any: [['request_type', REQ.MKT]] } },
  { key: 'portability_note', type: 'richtext',
    html: '<p>We will provide your personal data in a structured, machine-readable format (CSV or JSON) within one calendar month.</p>',
    showIf: { any: [['request_type', REQ.PORT]] } },

  { key: 'additional_info', type: 'textarea', label: 'Additional information (optional)' },

  { key: 'sec_declaration', type: 'section', label: 'Review & Declaration', newPage: true },
  { key: 'declaration', type: 'checkbox', label: 'Declaration', required: true,
    options: ['I declare the information is accurate, I am the data subject or duly authorised, and I understand my identity will be verified and the request handled within one calendar month (UK GDPR Art. 12(3)).'] },

  { key: 'source', type: 'text', label: 'source', hidden: true },
  { key: 'agent', type: 'text', label: 'agent', hidden: true },
];

// ---- API plumbing -----------------------------------------------------------
async function api(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json', Accept: 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = text; }
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${typeof json === 'string' ? json : JSON.stringify(json)}`);
  return json;
}

// NOTE: the CREATE endpoint uses the legacy logic shape (action/conditional/checks with
// field/condition/option) — different from what GET returns (action/operator/fields).
function buildLogic(showIf, idByKey) {
  if (!showIf) return null;
  const pairs = showIf.all || showIf.any;
  const conditional = showIf.all ? 'all' : 'any';
  const checks = pairs.map(([key, value]) => {
    const fieldId = idByKey[key];
    if (!fieldId) throw new Error(`logic references not-yet-created field "${key}"`);
    return { field: String(fieldId), condition: 'equals', option: value };
  });
  return { action: 'show', conditional, checks };
}

function payloadFor(f, order, idByKey) {
  const p = { type: f.type, label: f.label || '', displayOrder: order };
  if (f.required) p.required = true;
  if (f.hidden) p.hidden = true;
  if (f.hint) p.supportingText = f.hint;
  if (f.options) p.options = f.options.map((v) => ({ label: v, value: v }));
  if (f.type === 'section') { p.label = ''; p.attributes = { startNewPage: !!f.newPage, heading: f.label || '', text: f.hint || '' }; }
  if (f.type === 'richtext') { p.label = ''; p.attributes = { text: f.html || '', textEditor: 'wysiwyg' }; }
  const logic = buildLogic(f.showIf, idByKey);
  if (logic) p.logic = logic;
  return p;
}

// ---- run --------------------------------------------------------------------
(async () => {
  if (DELETE_ID && !DRY_RUN) {
    await api('DELETE', `/forms/${DELETE_ID}`);
    console.log(`Deleted form ${DELETE_ID}`);
    return;
  }

  console.log(DRY_RUN ? '=== DRY RUN (no API calls) ===\n' : `Creating form on ${BASE} ...\n`);
  const idByKey = {};
  const errors = [];

  let formId = 'DRYRUN-FORM';
  if (!DRY_RUN) {
    const form = await api('POST', '/forms', { name: FORM_NAME });
    formId = form.id || (form.form && form.form.id);
    console.log(`Form created: id=${formId}  "${form.name || FORM_NAME}"`);
  } else {
    console.log(`Would create form: "${FORM_NAME}"`);
  }

  let order = 0, fakeId = 1000;
  for (const f of FIELDS) {
    let payload;
    try { payload = payloadFor(f, order++, idByKey); }
    catch (e) { errors.push(`${f.key}: ${e.message}`); console.error(`  ! ${f.key}: ${e.message}`); continue; }

    if (DRY_RUN) {
      idByKey[f.key] = ++fakeId;
      const lg = payload.logic ? `  logic=${payload.logic.action}/${payload.logic.conditional}(${payload.logic.checks.map((c) => c.field + '=' + c.option).join(', ')})` : '';
      console.log(`  [${f.type}] ${f.key}${f.required ? ' *' : ''}${lg}`);
      continue;
    }
    try {
      const created = await api('POST', `/forms/${formId}/fields`, payload);
      const fid = created.id || (created.field && created.field.id);
      idByKey[f.key] = fid;
      console.log(`  ok  ${f.key.padEnd(22)} field ${fid} [${f.type}]`);
    } catch (e) {
      errors.push(`${f.key}: ${e.message}`);
      console.error(`  FAIL ${f.key}: ${e.message}`);
    }
  }

  console.log('\n--- field-id map (paste into docs/dsr-field-mapping.md) ---');
  for (const f of FIELDS) console.log(`  ${f.key.padEnd(22)} ${idByKey[f.key] ?? '???'}`);

  if (!DRY_RUN) {
    console.log(`\nFORM ID: ${formId}`);
    console.log(`Admin prefill: append  ?field${idByKey.source}=admin&field${idByKey.agent}=<adminId>  (verify Formstack's prefill query syntax)`);
  }
  console.log('\nNext: in the builder set the sections to pages if needed, then configure EU/UK region,');
  console.log('retention, reCAPTCHA, theme and the confirmation email (docs/formstack-dsr-build.md).');
  if (errors.length) {
    console.log(`\n${errors.length} field(s) errored:`);
    errors.forEach((e) => console.log('  - ' + e));
    process.exitCode = 1;
  } else {
    console.log('\nAll fields created with no errors.');
  }
})().catch((e) => { console.error('\nFATAL:', e.message); process.exit(1); });
