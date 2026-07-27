# backend/ — superseded (parked)

This Lambda turns a **custom-form** DSR submission into a Freshdesk ticket. It was built for the
self-hosted approach.

The project has since chosen the **Formstack** direction: a Formstack form → the workflow-system
→ Freshdesk (`docs/formstack-to-freshdesk-workflow.md`). In that design the **workflow-system
creates the ticket**, so this Lambda is **not deployed**.

It's kept as:
- a **reference** implementation of the Freshdesk ticket/tag/custom-field/attachment mapping, and
- a **fallback** if the self-hosted path is ever revisited (see `docs/backend-runbook.md`).

The offline test still passes (`node test/local-invoke.js`) and documents the intended mapping.
