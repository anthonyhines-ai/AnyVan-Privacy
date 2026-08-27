'use strict';

/**
 * Local, offline test for handler.js. Stubs global.fetch so no real Freshdesk
 * calls are made, invokes the Lambda with representative payloads, and asserts
 * the outgoing Freshdesk requests are shaped correctly.
 *
 * Run: node test/local-invoke.js   (from the backend/ directory; needs Node 18+)
 */

process.env.FRESHDESK_DOMAIN = 'anyvan-test';
process.env.FRESHDESK_API_KEY = 'test-key';
process.env.FRESHDESK_GROUP_ID = '999';

const calls = [];
function makeRes(status, obj) {
  return {
    ok: status >= 200 && status < 300,
    status,
    headers: { get: () => null },
    text: async () => JSON.stringify(obj),
  };
}
global.fetch = async (url, options) => {
  calls.push({ url, options });
  if (url.endsWith('/api/v2/tickets')) return makeRes(201, { id: 12345, status: 2 });
  if (/\/notes$/.test(url)) return makeRes(201, { id: 67890 });
  return makeRes(404, { error: 'unexpected url ' + url });
};

const { handler } = require('../handler');

let failures = 0;
function assert(cond, msg) {
  if (cond) { console.log('  ✓ ' + msg); } else { console.error('  ✗ ' + msg); failures++; }
}
const event = (payload) => ({ httpMethod: 'POST', body: JSON.stringify(payload), isBase64Encoded: false });
const lastTicketBody = () => JSON.parse(calls.find((c) => c.url.endsWith('/api/v2/tickets')).options.body);

async function run() {
  // --- Case 1: Customer SAR (call recordings) ---
  console.log('\nCase 1 — Customer SAR:');
  calls.length = 0;
  let r = await handler(event({
    dsr_reference: 'DSR-TEST1', requester_type: 'CUSTOMER', request_type: 'SAR',
    full_name: 'Jane Smith', email: 'jane@example.com', phone: '+447123456789',
    booking_reference: 'AV1234567', account_holder_confirmed: true,
    sar_data_types: ['call_recordings'],
    call_entries: [{ date: '2026-05-15', time: '14:30', phone: '+447123456789' }],
  }));
  assert(r.statusCode === 200, 'returns 200');
  let out = JSON.parse(r.body);
  assert(out.dsr_reference === 'DSR-TEST1', 'echoes DSR reference');
  assert(out.ticket_id === 12345, 'returns ticket_id');
  let tb = lastTicketBody();
  assert(tb.email === 'jane@example.com', 'ticket requester email set');
  assert(tb.custom_fields.cf_dsr_type === 'SAR', 'cf_dsr_type mapped');
  assert(tb.custom_fields.cf_requester_type === 'Customer', 'cf_requester_type mapped');
  assert(tb.custom_fields.cf_booking_reference === 'AV1234567', 'cf_booking_reference mapped');
  assert(tb.tags.includes('sar') && tb.tags.includes('customer') && tb.tags.includes('account-holder-confirmed'), 'tags include sar/customer/account-holder-confirmed');
  assert(tb.description.includes('2026-05-15'), 'description includes call date');
  assert(calls.some((c) => /\/notes$/.test(c.url)), 'private note posted');

  // --- Case 2: TP Limited deletion (no account-holder tag misuse) ---
  console.log('\nCase 2 — TP Limited deletion:');
  calls.length = 0;
  r = await handler(event({
    dsr_reference: 'DSR-TEST2', requester_type: 'TP', tp_business_type: 'limited', request_type: 'DELETION',
    full_name: 'Bob Jones', email: 'bob@haulage.co.uk', phone: '+447000000000',
    company_name: 'Jones Haulage Ltd', tp_username: 'bjones', account_holder_confirmed: true,
    deletion_scopes: ['full_account', 'marketing_data'],
  }));
  assert(r.statusCode === 200, 'returns 200');
  tb = lastTicketBody();
  assert(tb.custom_fields.cf_requester_type === 'TP Limited', 'cf_requester_type = TP Limited');
  assert(tb.custom_fields.cf_tp_username === 'bjones', 'cf_tp_username mapped');
  assert(tb.tags.includes('deletion') && tb.tags.includes('tp'), 'tags include deletion/tp');
  assert(tb.description.includes('Full account'), 'description lists deletion scope');

  // --- Case 3: Third party with attachment (multipart note) ---
  console.log('\nCase 3 — Third party w/ authorisation file:');
  calls.length = 0;
  r = await handler(event({
    dsr_reference: 'DSR-TEST3', requester_type: 'THIRD_PARTY', request_type: 'PORTABILITY',
    full_name: 'Data Subject', email: 'solicitor@law.co.uk', phone: '+447111111111',
    third_party_auth: 'Acting as solicitor under signed authority.',
    auth_files: [{ name: 'authority.pdf', size: 4, type: 'application/pdf', content_base64: Buffer.from('test').toString('base64') }],
  }));
  assert(r.statusCode === 200, 'returns 200');
  tb = lastTicketBody();
  assert(tb.custom_fields.cf_requester_type === 'Third Party', 'cf_requester_type = Third Party');
  assert(!tb.tags.includes('account-holder-confirmed'), 'no account-holder-confirmed tag for third party');
  const noteCall = calls.find((c) => /\/notes$/.test(c.url));
  assert(noteCall && typeof FormData !== 'undefined' && noteCall.options.body instanceof FormData, 'note posted as multipart FormData (attachment)');

  // --- Case 4: validation + CORS preflight ---
  console.log('\nCase 4 — validation & CORS:');
  r = await handler(event({ requester_type: 'CUSTOMER' }));
  assert(r.statusCode === 400, 'missing fields → 400');
  r = await handler({ httpMethod: 'OPTIONS' });
  assert(r.statusCode === 200 && r.headers['Access-Control-Allow-Origin'] === '*', 'OPTIONS preflight → 200 with CORS');

  console.log('\n' + (failures === 0 ? 'ALL TESTS PASSED' : failures + ' ASSERTION(S) FAILED'));
  process.exit(failures === 0 ? 0 : 1);
}

run().catch((e) => { console.error(e); process.exit(1); });
