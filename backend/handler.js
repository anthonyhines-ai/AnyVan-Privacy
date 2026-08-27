'use strict';

/**
 * DSR Intake Form → Freshdesk backend (AWS Lambda, Node.js 18+).
 *
 * Receives the JSON payload emitted by dsr-intake-form.html, creates a Freshdesk
 * ticket (custom fields + tags), adds a structured private note with the full
 * request breakdown, attaches any third-party authorisation files, and returns
 * the DSR reference to the form. Creating the ticket emits a
 * FRESHDESK_TICKET_CREATED event, which the existing workflow-system classifier
 * picks up for routing — this Lambda does not classify or route itself.
 *
 * No third-party dependencies: uses the global fetch/FormData/Blob available in
 * the Node.js 18+ Lambda runtime.
 *
 * Required environment variables:
 *   FRESHDESK_DOMAIN   e.g. "anyvan"  (→ https://anyvan.freshdesk.com) — or a full base URL
 *   FRESHDESK_API_KEY  Freshdesk API key (used as basic-auth username, password "X")
 * Optional:
 *   FRESHDESK_GROUP_ID     numeric group to assign tickets to
 *   ALLOWED_ORIGIN         CORS allow-origin (default "*")
 *   CF_DSR_TYPE            override for the cf_* key of the DSR-type field (default cf_dsr_type)
 *   CF_REQUESTER_TYPE      override (default cf_requester_type)
 *   CF_BOOKING_REFERENCE   override (default cf_booking_reference)
 *   CF_TP_USERNAME         override (default cf_tp_username)
 *
 * The cf_* overrides exist because Freshdesk renames a custom field's internal
 * key when its type changes (e.g. cf_booking_reference → cf_booking_reference594255).
 * Confirm the live keys with GET /api/v2/ticket_fields and set the env vars if they
 * differ from the defaults.
 */

const DSR_TYPE_LABELS = {
  SAR: 'SAR',
  DELETION: 'Deletion',
  RECTIFICATION: 'Rectification',
  MARKETING_OPT_OUT: 'Marketing Opt-Out',
  PORTABILITY: 'Portability',
};

const SAR_TYPE_LABELS = {
  booking_data: 'Booking & account details',
  call_recordings: 'Call recordings',
  chat_transcripts: 'Chat transcripts',
  email_correspondence: 'Email correspondence',
  payment_data: 'Payment & transaction records',
  all_data: 'All personal data held',
};

const DEL_SCOPE_LABELS = {
  full_account: 'Full account and all associated data',
  booking_history: 'Booking history only',
  call_recordings_del: 'Call recordings only',
  chat_transcripts_del: 'Chat transcripts only',
  marketing_data: 'Marketing/mailing list data only',
};

const RECT_FIELD_LABELS = {
  name: 'Name',
  email: 'Email address',
  phone: 'Phone number',
  address: 'Address',
  other_field: 'Other',
};

function requesterTypeLabel(p) {
  if (p.requester_type === 'CUSTOMER') return 'Customer';
  if (p.requester_type === 'TP') {
    return p.tp_business_type === 'sole_trader' ? 'TP Sole Trader' : 'TP Limited';
  }
  if (p.requester_type === 'THIRD_PARTY') return 'Third Party';
  return p.requester_type || 'Unknown';
}

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

/** Authoritatively derive tags from the payload (do not trust client tags blindly). */
function buildTags(p) {
  const tags = ['privacy', 'dsr'];
  if (p.request_type) tags.push(String(p.request_type).toLowerCase());
  if (p.requester_type) tags.push(String(p.requester_type).toLowerCase().replace(/_/g, '-'));
  tags.push('source:dsr-form');
  if (p.account_holder_confirmed === true) tags.push('account-holder-confirmed');
  return Array.from(new Set(tags));
}

function buildCustomFields(p, keys) {
  const cf = {};
  cf[keys.dsrType] = DSR_TYPE_LABELS[p.request_type] || p.request_type || null;
  cf[keys.requesterType] = requesterTypeLabel(p);
  if (p.booking_reference) cf[keys.bookingReference] = p.booking_reference;
  if (p.tp_username) cf[keys.tpUsername] = p.tp_username;
  return cf;
}

/** Human-readable HTML breakdown of the request (used for description + private note). */
function buildDetailsHtml(p, ref) {
  const rows = [];
  const add = (k, v) => { if (v !== undefined && v !== null && v !== '') rows.push([k, v]); };

  add('DSR reference', ref);
  add('Submitted at', p.submitted_at);
  add('Requester type', requesterTypeLabel(p));
  add('Name', p.full_name);
  add('Email', p.email);
  add('Phone', p.phone + (p.alt_phone ? ' / ' + p.alt_phone : ''));
  if (p.company_name) add(p.tp_business_type === 'sole_trader' ? 'Trading name' : 'Company', p.company_name);
  if (p.tp_username) add('TP username', p.tp_username);
  if (p.booking_reference) add('Booking reference', p.booking_reference);
  if (p.requester_type === 'CUSTOMER' || p.requester_type === 'TP') add('Account holder confirmed', p.account_holder_confirmed ? 'Yes' : 'No');
  if (p.requester_type === 'THIRD_PARTY') {
    add('Authorisation basis', p.third_party_auth);
    if (Array.isArray(p.auth_files) && p.auth_files.length) {
      add('Authorisation files', p.auth_files.map((f) => f.name).join(', '));
    }
  }
  add('Request type', DSR_TYPE_LABELS[p.request_type] || p.request_type);

  if (p.request_type === 'SAR' && Array.isArray(p.sar_data_types)) {
    add('Data requested', p.sar_data_types.map((t) => SAR_TYPE_LABELS[t] || t).join(', '));
    if (Array.isArray(p.call_entries) && p.call_entries.length) {
      add('Call recordings', p.call_entries.map((c) => `${c.date}${c.time ? ' ~' + c.time : ''}${c.phone ? ' (' + c.phone + ')' : ''}`).join(' · '));
    }
    if (p.chat_request) {
      add('Chat transcripts', `${p.chat_request.date_from || '?'} → ${p.chat_request.date_to || '?'} · ${(p.chat_request.channels || []).join(', ')}`);
    }
    if (p.all_data_request) {
      add('All-data window', `${p.all_data_request.date_from || '?'} → ${p.all_data_request.date_to || '?'}`);
      add('All-data reason', p.all_data_request.reason);
    }
  }
  if (p.request_type === 'DELETION' && Array.isArray(p.deletion_scopes)) {
    add('Deletion scope', p.deletion_scopes.map((s) => DEL_SCOPE_LABELS[s] || s).join(', '));
  }
  if (p.request_type === 'RECTIFICATION') {
    if (Array.isArray(p.rectification_fields)) add('Fields to correct', p.rectification_fields.map((f) => RECT_FIELD_LABELS[f] || f).join(', '));
    add('Correction details', p.rectification_details);
  }
  add('Additional information', p.additional_info);

  const trs = rows.map(([k, v]) => `<tr><td style="padding:4px 12px 4px 0;font-weight:600;vertical-align:top;white-space:nowrap">${esc(k)}</td><td style="padding:4px 0">${esc(v)}</td></tr>`).join('');
  return `<table style="border-collapse:collapse;font-size:13px">${trs}</table>`;
}

// ---- Freshdesk HTTP helpers -------------------------------------------------

function freshdeskBaseUrl() {
  const domain = process.env.FRESHDESK_DOMAIN;
  if (!domain) throw new Error('FRESHDESK_DOMAIN not set');
  if (domain.startsWith('http')) return domain.replace(/\/$/, '');
  return `https://${domain}.freshdesk.com`;
}

function authHeader() {
  const key = process.env.FRESHDESK_API_KEY;
  if (!key) throw new Error('FRESHDESK_API_KEY not set');
  return 'Basic ' + Buffer.from(`${key}:X`).toString('base64');
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** fetch with 429/5xx retry honouring Retry-After. */
async function freshdeskFetch(path, options, attempt = 0) {
  const res = await fetch(freshdeskBaseUrl() + path, options);
  if ((res.status === 429 || res.status >= 500) && attempt < 4) {
    const retryAfter = parseInt(res.headers.get('retry-after') || '', 10);
    const waitMs = Number.isFinite(retryAfter) ? retryAfter * 1000 : Math.min(2000 * 2 ** attempt, 16000);
    await sleep(waitMs);
    return freshdeskFetch(path, options, attempt + 1);
  }
  return res;
}

async function createTicket(p, ref, keys) {
  const body = {
    name: p.full_name || 'DSR requester',
    email: p.email,
    subject: `DSR ${ref} — ${DSR_TYPE_LABELS[p.request_type] || p.request_type} (${requesterTypeLabel(p)})`,
    description: `<p><strong>Data Subject Request ${esc(ref)}</strong></p>${buildDetailsHtml(p, ref)}`,
    status: 2,
    priority: 2,
    tags: buildTags(p),
    custom_fields: buildCustomFields(p, keys),
  };
  if (p.phone) body.phone = p.phone;
  if (process.env.FRESHDESK_GROUP_ID) body.group_id = Number(process.env.FRESHDESK_GROUP_ID);

  const res = await freshdeskFetch('/api/v2/tickets', {
    method: 'POST',
    headers: { Authorization: authHeader(), 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Freshdesk ticket create failed: ${res.status} ${text}`);
  return JSON.parse(text);
}

async function addPrivateNote(ticketId, p, ref) {
  const note = `<p><strong>DSR ${esc(ref)} — full request breakdown</strong></p>${buildDetailsHtml(p, ref)}`;
  const files = Array.isArray(p.auth_files) ? p.auth_files.filter((f) => f && f.content_base64) : [];

  let options;
  if (files.length) {
    // Multipart so we can attach the authorisation files.
    const form = new FormData();
    form.append('body', note);
    form.append('private', 'true');
    for (const f of files) {
      const bytes = Buffer.from(f.content_base64, 'base64');
      form.append('attachments[]', new Blob([bytes], { type: f.type || 'application/octet-stream' }), f.name || 'attachment');
    }
    options = { method: 'POST', headers: { Authorization: authHeader() }, body: form };
  } else {
    options = {
      method: 'POST',
      headers: { Authorization: authHeader(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ body: note, private: true }),
    };
  }

  const res = await freshdeskFetch(`/api/v2/tickets/${ticketId}/notes`, options);
  const text = await res.text();
  if (!res.ok) throw new Error(`Freshdesk note failed: ${res.status} ${text}`);
  return JSON.parse(text);
}

// ---- Lambda entrypoint ------------------------------------------------------

function cfKeys() {
  return {
    dsrType: process.env.CF_DSR_TYPE || 'cf_dsr_type',
    requesterType: process.env.CF_REQUESTER_TYPE || 'cf_requester_type',
    bookingReference: process.env.CF_BOOKING_REFERENCE || 'cf_booking_reference',
    tpUsername: process.env.CF_TP_USERNAME || 'cf_tp_username',
  };
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };
}

function reply(statusCode, obj) {
  return { statusCode, headers: corsHeaders(), body: JSON.stringify(obj) };
}

/** Extract HTTP method from either REST (v1) or HTTP-API (v2) proxy events. */
function httpMethod(event) {
  return (event && (event.httpMethod || (event.requestContext && event.requestContext.http && event.requestContext.http.method))) || 'POST';
}

exports.handler = async (event) => {
  if (httpMethod(event) === 'OPTIONS') return reply(200, { ok: true });

  let p;
  try {
    let raw = event && event.body != null ? event.body : event;
    if (event && event.isBase64Encoded && typeof raw === 'string') raw = Buffer.from(raw, 'base64').toString('utf8');
    p = typeof raw === 'string' ? JSON.parse(raw) : raw;
  } catch (e) {
    return reply(400, { error: 'invalid JSON body' });
  }

  if (!p || !p.email || !p.request_type || !p.requester_type) {
    return reply(400, { error: 'missing required fields (email, request_type, requester_type)' });
  }

  const ref = p.dsr_reference || 'DSR-' + Date.now().toString(36).toUpperCase();

  try {
    const ticket = await createTicket(p, ref, cfKeys());
    try {
      await addPrivateNote(ticket.id, p, ref);
    } catch (noteErr) {
      // Ticket exists; a failed note should not lose the request. Log and continue.
      console.error('note/attachment failed for ticket', ticket.id, noteErr.message);
    }
    return reply(200, { dsr_reference: ref, ticket_id: ticket.id });
  } catch (err) {
    console.error('DSR submission failed:', err.message);
    return reply(502, { error: 'failed to create Freshdesk ticket', detail: err.message });
  }
};
