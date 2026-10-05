// Freshworks serverless handler — auto-merge DSR customer-reply tickets into the original.
//
// Fires on every new ticket. If the ticket is a customer reply to a Formstack-sent DSR
// confirmation ("Re: Your AnyVan Privacy Request: Reference DSR-<id>"), it finds the original
// workflow-created ticket ("... [<id>]") and merges the reply into it — but ONLY when exactly one
// original matches the submission id AND the requester is the same contact, within the privacy
// groups. Anything ambiguous is left untouched for a human.
//
// Runs on Freshworks' serverless platform — nothing to host.

const REPLY_RE    = /Reference\s+DSR-(\d+)/i;  // reply ticket subject -> submission id
const ORIGINAL_RE = /\[(\d+)\]\s*$/;           // original ticket subject ends with [submission id]
const isClosedish = (s) => s === 4 || s === 5; // 4 resolved, 5 closed

exports = {
  onTicketCreateHandler: async function (args) {
    try {
      const t = args.data.ticket;
      const reply = (t.subject || "").match(REPLY_RE);
      if (!reply) return;                          // not a DSR reply ticket — ignore
      const id = reply[1];

      const groups = String(args.iparams.privacy_group_ids || "")
        .split(",").map((s) => s.trim()).filter(Boolean);
      if (groups.length && !groups.includes(String(t.group_id))) return; // outside privacy groups

      const domain = args.iparams.freshdesk_domain;      // e.g. anyvan.freshdesk.com
      const key = args.iparams.freshdesk_api_key;        // secure iparam
      const headers = {
        Authorization: "Basic " + Buffer.from(key + ":X").toString("base64"),
        "Content-Type": "application/json",
      };

      // Candidate originals: open/pending tickets in the privacy groups.
      const gq = groups.length ? "(" + groups.map((g) => `group_id:${g}`).join(" OR ") + ") AND " : "";
      const query = encodeURIComponent(`"${gq}(status:2 OR status:3)"`);
      const res = await $request.get(`https://${domain}/api/v2/search/tickets?query=${query}`, { headers });
      const results = (JSON.parse(res.response).results) || [];

      const originals = results.filter((x) => {
        const o = (x.subject || "").match(ORIGINAL_RE);
        return o && o[1] === id && x.id !== t.id && !isClosedish(x.status);
      });

      if (originals.length !== 1) return;                // 0 or >1 -> leave for a human
      const orig = originals[0];
      if (orig.requester_id !== t.requester_id) return;  // different data subject -> NEVER merge

      const body = {
        primary_id: orig.id,
        ticket_ids: [t.id],
        convert_recepients_to_cc: true, // Freshdesk's spelling; keeps the replier on the primary
        note_in_primary: { body: `Auto-merged customer reply ticket #${t.id} (DSR-${id}).`, private: true },
      };
      await $request.put(`https://${domain}/api/v2/tickets/merge`, { headers, body: JSON.stringify(body) });
      console.log(`Merged reply #${t.id} -> original #${orig.id} (DSR-${id})`);
    } catch (e) {
      console.error("DSR merge handler error:", (e && e.message) ? e.message : e);
    }
  },
};
