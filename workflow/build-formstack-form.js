#!/usr/bin/env node
'use strict';

/*
 * Build / update the AnyVan DSR (Data Subject Rights Request) form in Formstack via the V2025 API.
 *
 * Mirrors AnyVan's official DSRR template (AnyVan_DSRR_Form.docx) and the internal
 * dsr-intake-form.html — see docs/formstack-dsr-build.md and docs/dsr-field-mapping.md.
 *
 *   # create a brand-new form with every field + conditional logic:
 *   FORMSTACK_TOKEN=<fs_pat_...> node workflow/build-formstack-form.js
 *
 *   # preview the planned structure — no token, no API calls:
 *   node workflow/build-formstack-form.js --dry-run
 *   node workflow/build-formstack-form.js --form 6559077 --dry-run   # preview the additive update
 *
 *   # ADD only the newer fields to the EXISTING live form and refresh the request-type
 *   # options (does NOT recreate the form — safe to run against form 6559077):
 *   FORMSTACK_TOKEN=<fs_pat_...> node workflow/build-formstack-form.js --form 6559077
 *
 *   # remove a form created by mistake:
 *   FORMSTACK_TOKEN=... node workflow/build-formstack-form.js --delete <formId>
 *
 * Auth: a Formstack Personal Access Token (fs_pat_...) sent as `Authorization: Bearer`.
 * API: V2025, base https://www.formstack.com/api/v2025 (endpoints/shapes confirmed against a
 * live AnyVan form). Prints the field-id map at the end for docs/dsr-field-mapping.md.
 * On a field error it logs the response and continues.
 */

const BASE = 'https://www.formstack.com/api/v2025';
const TOKEN = process.env.FORMSTACK_TOKEN || '';
const argFlag = (name) => process.argv.includes(name);
const argVal = (name) => (argFlag(name) ? process.argv[process.argv.indexOf(name) + 1] : null);
const DRY_RUN = argFlag('--dry-run') || !TOKEN;
const DELETE_ID = argVal('--delete');
const UPDATE_FORM_ID = argVal('--form'); // additive update of an existing form
const FORM_NAME = 'AnyVan — Data Subject Request (DSR)';

// ---- known live field ids (form 6559077) ----------------------------------
// Used by --form (additive) mode to resolve conditional-logic references to fields that
// already exist, and to PATCH the request_type options. Keep in sync with
// docs/dsr-field-mapping.md if the live form is rebuilt.
const LIVE_IDS = {
  sec_requester: 197276067, requester_type: 197276069,
  sec_details: 197276070, full_name: 197276071, email: 197276072, phone: 197276073,
  alt_phone: 197276074, booking_reference: 197276080,
  business_type: 197276081, trading_name: 197276082, company_name: 197276083, tp_username: 197276084,
  third_party_auth: 197276085, auth_file: 197276086, account_holder: 197276087,
  sec_request: 197276088, request_type: 197276089, sar_data_types: 197276090,
  call_from: 197277114, call_to: 197277122,
  chat_from: 197276092, chat_to: 197276093, chat_channels: 197276094,
  all_data_from: 197276095, all_data_to: 197276096, all_data_reason: 197276097,
  deletion_scopes: 197276099, rectification_fields: 197276100, rectification_details: 197276101,
  additional_info: 197276106, sec_declaration: 197276107, declaration: 197276108,
  source: 197276151, agent: 197276152,
};

// ---- vocab ------------------------------------------------------------------
const REQUESTER = { CUST: 'Customer', TP: 'Transport Partner', TP3: 'Authorised Third Party' };
const BIZ = { SOLE: 'Sole Trader', LTD: 'Limited Company or Partnership' };
// The 8 statutory UK-GDPR rights from the official DSRR template, plus the customer-friendly
// "Marketing Opt-Out" (a common subset of objection / withdrawal of consent).
const REQ = {
  SAR: 'Access My Data (SAR)', DEL: 'Delete My Data', RECT: 'Correct My Data',
  RESTRICT: 'Restrict Processing', PORT: 'Data Portability', OBJECT: 'Object to Processing',
  ADM: 'Automated Decision-Making', WITHDRAW: 'Withdraw Consent', MKT: 'Marketing Opt-Out',
};
// Full option list for the request-type radio (order mirrors the template, marketing last).
const REQUEST_TYPE_OPTIONS = [REQ.SAR, REQ.RECT, REQ.DEL, REQ.RESTRICT, REQ.PORT, REQ.OBJECT,
  REQ.ADM, REQ.WITHDRAW, REQ.MKT];
// NB: "Payment & transaction records" was removed on the live form (5 categories).
const SAR_CATS = ['Booking & account details', 'Call recordings', 'Chat transcripts',
  'Email correspondence', 'All personal data held'];

// showIf: { any:[[key,value],...] } -> OR ; { all:[...] } -> AND
const CUST_OR_TP = { any: [['requester_type', REQUESTER.CUST], ['requester_type', REQUESTER.TP]] };
const IF_TP3 = { any: [['requester_type', REQUESTER.TP3]] };

// isNew: created by --form (additive) mode. Fields without it already exist on form 6559077.
const FIELDS = [
  { key: 'intro_note', type: 'richtext', isNew: true,
    html: '<p><strong>AnyVan — Data Subject Rights Request</strong></p>'
      + '<p>Use this form to exercise your rights under UK GDPR. Your request is handled by '
      + "AnyVan's Data Protection Manager (privacy@anyvan.com) and answered within "
      + '<strong>one calendar month</strong>. We will verify your identity before releasing or '
      + 'changing any data. If you attach documents, please send <strong>copies only — never '
      + 'originals</strong>.</p>' },

  { key: 'sec_requester', type: 'section', label: 'Who is making this request?' },
  { key: 'requester_type', type: 'radio', label: 'Requester type', required: true,
    options: [REQUESTER.CUST, REQUESTER.TP, REQUESTER.TP3] },

  { key: 'sec_details', type: 'section', label: "Data Subject's Details", newPage: true,
    hint: 'The person the data is about. If you are acting for someone else, enter their details '
      + 'here and add your own in the Third Party section. Fields marked * are required.' },
  { key: 'title', type: 'text', label: 'Title (optional)', isNew: true },
  { key: 'full_name', type: 'text', label: 'Full name (of the data subject)', required: true },
  { key: 'email', type: 'email', label: 'Email address', required: true },
  { key: 'phone', type: 'text', label: 'Phone number', required: true, hint: 'Include country code, e.g. +44 7…' },
  { key: 'alt_phone', type: 'text', label: 'Alternative phone number' },
  { key: 'data_subject_address', type: 'textarea', label: 'Postal address (optional)', isNew: true,
    hint: 'Helps us verify your identity and, where needed, correspond by post.' },
  { key: 'booking_reference', type: 'text', label: 'AnyVan booking reference (if any)', hint: 'e.g. AV1234567' },

  // Identity Verification (data-subject paths). Mirrors the template's dedicated section.
  { key: 'sec_identity', type: 'section', label: 'Identity Verification', isNew: true,
    hint: 'So we can safely confirm who you are before releasing or changing data. Please send '
      + 'copies only — never originals — and do not include full card numbers.',
    showIf: CUST_OR_TP },
  { key: 'id_details', type: 'textarea', label: 'Information to help us verify your identity (optional)',
    isNew: true, showIf: CUST_OR_TP },
  { key: 'id_document', type: 'file', label: 'Identity document — copy only (optional, PDF/JPG/PNG)',
    isNew: true, hint: 'Upload a copy, not an original. Redact anything not needed to confirm your identity.',
    showIf: CUST_OR_TP },

  // Transport Partner
  { key: 'business_type', type: 'radio', label: 'Business type', required: true,
    options: [BIZ.SOLE, BIZ.LTD], showIf: { any: [['requester_type', REQUESTER.TP]] } },
  { key: 'trading_name', type: 'text', label: 'Trading name (optional)',
    showIf: { any: [['business_type', BIZ.SOLE]] } },
  { key: 'company_name', type: 'text', label: 'Registered company / partnership name', required: true,
    showIf: { any: [['business_type', BIZ.LTD]] } },
  { key: 'tp_username', type: 'text', label: 'Transport Partner username (optional)',
    showIf: { any: [['requester_type', REQUESTER.TP]] } },

  // Authorised Third Party — the acting party's OWN details + relationship + proof.
  { key: 'sec_third_party', type: 'section', label: 'Third Party Acting for the Data Subject',
    isNew: true, hint: 'Your own details as the person making this request on the data subject\'s behalf.',
    showIf: IF_TP3 },
  { key: 'tp3_name', type: 'text', label: 'Your full name', required: true, isNew: true, showIf: IF_TP3 },
  { key: 'tp3_email', type: 'email', label: 'Your email address', required: true, isNew: true, showIf: IF_TP3 },
  { key: 'tp3_phone', type: 'text', label: 'Your phone number (optional)', isNew: true, showIf: IF_TP3 },
  { key: 'third_party_auth', type: 'textarea', label: 'Authorisation details', required: true,
    hint: 'Your relationship to the data subject and the basis for your authorisation.',
    showIf: IF_TP3 },
  { key: 'auth_file', type: 'file', label: 'Proof of authorisation — copy only (PDF/JPG/PNG)', required: true,
    hint: 'Please upload a copy, not an original (e.g. signed letter of authority or power of attorney).',
    showIf: IF_TP3 },

  { key: 'account_holder', type: 'checkbox', label: 'Account-holder confirmation', required: true,
    options: ['I confirm I am the account holder / authorised to make this request'],
    showIf: CUST_OR_TP },

  { key: 'sec_request', type: 'section', label: 'Your Request', newPage: true },
  { key: 'request_type', type: 'radio', label: 'What would you like us to do?', required: true,
    options: REQUEST_TYPE_OPTIONS },

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

  // The 4 rights added to align with the template. Each gives a short explanation and directs the
  // requester to the shared "Additional information" box for specifics (as the template does).
  { key: 'restrict_note', type: 'richtext', isNew: true,
    html: '<p>We will restrict (pause) processing of your data while a concern is resolved. Please tell us which processing and why in <em>Additional information</em> below.</p>',
    showIf: { any: [['request_type', REQ.RESTRICT]] } },
  { key: 'object_note', type: 'richtext', isNew: true,
    html: '<p>You can object to how we process your data (for example, direct marketing, or processing based on our legitimate interests). Please tell us what you object to, and your grounds, in <em>Additional information</em> below.</p>',
    showIf: { any: [['request_type', REQ.OBJECT]] } },
  { key: 'adm_note', type: 'richtext', isNew: true,
    html: '<p>You can ask us not to make a decision about you based solely on automated processing, or to review one that was already made. Please tell us which decision in <em>Additional information</em> below.</p>',
    showIf: { any: [['request_type', REQ.ADM]] } },
  { key: 'withdraw_note', type: 'richtext', isNew: true,
    html: '<p>Where we rely on your consent, you can withdraw it at any time. This does not affect any processing carried out before you withdrew. Please tell us which consent in <em>Additional information</em> below.</p>',
    showIf: { any: [['request_type', REQ.WITHDRAW]] } },

  { key: 'additional_info', type: 'textarea', label: 'Additional information related to your request (optional)' },

  { key: 'sec_declaration', type: 'section', label: 'Review & Declaration', newPage: true },
  { key: 'signature_name', type: 'text', label: 'Full name (this acts as your signature)', required: true, isNew: true },
  { key: 'declaration', type: 'checkbox', label: 'Declaration', required: true,
    options: ['I declare the information given is accurate. I am the data subject named above, or a third party duly authorised to act on their behalf. I understand my identity (and authority, if acting for someone else) will be verified, and the request handled within one calendar month (UK GDPR Art. 12(3)).'] },

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

async function createField(formId, f, order, idByKey, errors, dry) {
  let payload;
  try { payload = payloadFor(f, order, idByKey); }
  catch (e) { errors.push(`${f.key}: ${e.message}`); console.error(`  ! ${f.key}: ${e.message}`); return; }

  if (dry) {
    idByKey[f.key] = idByKey[f.key] || `NEW-${f.key}`;
    const lg = payload.logic
      ? `  logic=${payload.logic.action}/${payload.logic.conditional}(${payload.logic.checks.map((c) => c.field + '=' + c.option).join(', ')})`
      : '';
    console.log(`  [${f.type}] ${f.key}${f.required ? ' *' : ''}${f.isNew ? ' (new)' : ''}${lg}`);
    return;
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

// ---- run --------------------------------------------------------------------
(async () => {
  if (DELETE_ID && !DRY_RUN) {
    await api('DELETE', `/forms/${DELETE_ID}`);
    console.log(`Deleted form ${DELETE_ID}`);
    return;
  }

  const errors = [];

  // ---------- additive update of an existing form ----------
  if (UPDATE_FORM_ID) {
    const formId = UPDATE_FORM_ID;
    console.log(DRY_RUN
      ? `=== DRY RUN — additive update of form ${formId} (no API calls) ===\n`
      : `Additive update of form ${formId} on ${BASE} ...\n`);

    const idByKey = { ...LIVE_IDS }; // seed so new-field logic can resolve existing fields

    // 1) refresh the request_type options to the full statutory set
    const fieldId = LIVE_IDS.request_type;
    const options = REQUEST_TYPE_OPTIONS.map((v) => ({ label: v, value: v }));
    if (DRY_RUN) {
      console.log(`  would set request_type (${fieldId}) options -> ${REQUEST_TYPE_OPTIONS.join(' | ')}`);
    } else {
      try {
        await api('PUT', `/forms/${formId}/fields/${fieldId}`, { options });
        console.log(`  ok  request_type (${fieldId}) options updated -> ${REQUEST_TYPE_OPTIONS.length} options`);
      } catch (e) {
        console.error(`  FAIL updating request_type options: ${e.message}`);
        console.error(`       Add these options manually in the builder: ${REQUEST_TYPE_OPTIONS.join(' | ')}`);
        errors.push(`request_type options: ${e.message}`);
      }
    }

    // 2) create ONLY the new fields (appended; reorder in the builder afterwards)
    let order = 1000;
    const newFields = FIELDS.filter((f) => f.isNew);
    console.log(`\n  Creating ${newFields.length} new field(s):`);
    for (const f of newFields) {
      // eslint-disable-next-line no-await-in-loop
      await createField(formId, f, order++, idByKey, errors, DRY_RUN);
    }

    console.log('\n--- new field-id map (add to docs/dsr-field-mapping.md) ---');
    for (const f of newFields) console.log(`  ${f.key.padEnd(22)} ${idByKey[f.key] ?? '???'}`);
    console.log('\nNext: in the builder, drag the new fields into place (Identity Verification after the');
    console.log('data-subject details; the Third Party block near the authorisation fields; each rights');
    console.log('note inside the request panel), then re-check the field ids in docs/dsr-field-mapping.md.');
    finish(errors);
    return;
  }

  // ---------- create a brand-new form ----------
  console.log(DRY_RUN ? '=== DRY RUN (no API calls) ===\n' : `Creating form on ${BASE} ...\n`);
  const idByKey = {};

  let formId = 'DRYRUN-FORM';
  if (!DRY_RUN) {
    const form = await api('POST', '/forms', { name: FORM_NAME });
    formId = form.id || (form.form && form.form.id);
    console.log(`Form created: id=${formId}  "${form.name || FORM_NAME}"`);
  } else {
    console.log(`Would create form: "${FORM_NAME}"`);
  }

  let order = 0;
  for (const f of FIELDS) {
    // eslint-disable-next-line no-await-in-loop
    await createField(formId, f, order++, idByKey, errors, DRY_RUN);
  }

  console.log('\n--- field-id map (paste into docs/dsr-field-mapping.md) ---');
  for (const f of FIELDS) console.log(`  ${f.key.padEnd(22)} ${idByKey[f.key] ?? '???'}`);

  if (!DRY_RUN) {
    console.log(`\nFORM ID: ${formId}`);
    console.log(`Admin prefill: append  ?field${idByKey.source}=admin&field${idByKey.agent}=<adminId>  (verify Formstack's prefill query syntax)`);
  }
  console.log('\nNext: in the builder set the sections to pages if needed, then configure EU/UK region,');
  console.log('retention, reCAPTCHA, theme and the confirmation email (docs/formstack-dsr-build.md).');
  finish(errors);
})().catch((e) => { console.error('\nFATAL:', e.message); process.exit(1); });

function finish(errors) {
  if (errors.length) {
    console.log(`\n${errors.length} field(s) errored:`);
    errors.forEach((e) => console.log('  - ' + e));
    process.exitCode = 1;
  } else {
    console.log('\nAll fields processed with no errors.');
  }
}
