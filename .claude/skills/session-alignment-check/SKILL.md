---
name: session-alignment-check
description: >
  Review what THIS session/branch actually changed (dashboards, queries, docs, CLAUDE.md, skills)
  and confirm it's all internally aligned and matches what's really live on the platform, before
  the session ends. Use at the end of any session that touched an AV Dashboards page, a Snowflake
  query, a workflow-system workflow, or CLAUDE.md/README/a skill describing any of those. Also use
  on explicit request ("check we're aligned", "did we leave anything inconsistent", "run the
  alignment check"). Scoped to the session's own diff, not a full historical repo re-audit — for
  that, a full manual sweep is the right tool, not this skill. Never commits or deploys on its own;
  reports findings and applies only unambiguous, mechanical doc fixes when asked to fix.
---

# Session alignment check

Built 2026-11-12 after two real incidents in the same session: a live dashboard query was
misdiagnosed because it was checked without `dashboard_id`, and the "fix" for that regressed a
production dashboard by deploying from a stale repo copy. This skill exists so the next session
checks for exactly those failure modes before calling anything done — mechanically, not by memory.

**Read the repo's own `CLAUDE.md` first.** It defines this repo's file-tree convention, PII/banner
rules (if any), deploy mechanics, and its own "Change discipline" section — this skill operationalises
that, it doesn't replace it. If `CLAUDE.md` and this skill ever disagree, `CLAUDE.md` wins; fix this
skill to match, don't silently follow the stale version here.

## 0. Scope: the session's own diff, not the whole repo

This is not another full sweep. Find what this session actually touched:

```bash
git status --short                                   # uncommitted work
git log --oneline <default-branch>..HEAD              # commits this session/branch made
git diff <default-branch>...HEAD --stat                # full file-level diff vs where the branch started
```

Everything below is scoped to files that diff touches, plus anything those files reference (e.g. a
touched dashboard HTML's query names), not the rest of the repo. If nothing in this session touched
a dashboard, a query, a doc, or CLAUDE.md, say so and stop — there's nothing to check.

## 1. Every touched dashboard HTML

For each `*.html` file in the diff that is (or was already, before this session) a deployed AV
Dashboards page:

1. **Diff the repo file against the real live HTML before trusting either one.**
   `mcp__AV_Dashboards__get_dashboard_html(path: "<dashboard path>")` and diff it against the repo
   file. If they differ and this session did NOT deploy this session, that's pre-existing drift —
   report it, don't silently pick a side. If this session DID deploy, confirm the live HTML now
   matches the repo file exactly (a clean deploy), not a stale subset of it.
2. **Extract every `AVDashboard.runQuery('name', ...)` call** and for each query name:
   - Confirm a matching `*.sql` file exists in the repo (same name, hyphen/underscore-normalised).
   - **Check what the dashboard is actually pinned to, not what the bare name returns.**
     `mcp__AV_Dashboards__get_query(query_id: "<name>", include_sql: true, dashboard_id: "<dashboard
     path>")` — its "Version run by dashboard" line is the ground truth. A bare call with no
     `dashboard_id` can silently return a different, older, unpinned saved version of the same
     query name. **Never diagnose or report on a live query without `dashboard_id` set** — this is
     exactly the mistake that caused the 2026-11-11/12 Payment Management incident.
   - Confirm the repo's `*.sql` file's content matches what's actually pinned (above), not some
     other version of the same name. If they differ, the repo file is stale — flag it, and update
     it from the dashboard-scoped SQL, never the bare-name SQL.
3. **If this session changed a query's logic**, confirm it went through `create_query` under a new,
   bumped name — never `update_query` on an existing name for a logic change (that's indistinguishable
   from the query just quietly drifting, with nothing in the repo able to catch it later).
4. **If this session deployed anything**, confirm via `execute_query(..., dashboard_id: ...)` that
   real output looks sane (no empty result where rows are expected, no column that's unexpectedly
   null/missing) — not just that Snowflake accepted the SQL.

## 2. Every touched query SQL file

- If the file's AV Dashboards query name already existed before this session (check `git log` on
  the file) and its logic changed, confirm the name was bumped (new file, old one marked
  SUPERSEDED in its own header, not deleted) rather than edited in place.
- If a file is now marked SUPERSEDED, confirm nothing still deployed references its old name.

## 3. Every touched doc (CLAUDE.md, README, skills, any `.md`)

- If this session's other changes imply something a doc should now say (a new/removed top-level
  folder, a renamed/retired/superseded file, a promoted/archived workflow, a query version bump,
  a dashboard's feature set changing), confirm the relevant doc was updated in the **same** set of
  commits — not left as an implied follow-up.
- If a repo convention requires a banner on certain files (check `CLAUDE.md` — e.g. AnyVan-Privacy's
  CONFIDENTIAL/PII vs INTERNAL rule), confirm every new/touched file under those folders has one.
- Flag any new "reconcile later" / "flag for review" language with no owner or date — per the repo's
  own change-discipline rule, that's not a resolution, it's a drift waiting to happen.

## 4. Run the repo's static check

```bash
python3 scripts/check_consistency.py
```

This catches file-tree drift, a dashboard referencing a query with no repo file, missing banners,
and committed secrets — mechanically, across the whole repo, not just the session's diff. Run it
regardless of scope; it's cheap and repo-wide by design. Fix anything it finds that's within this
session's own changes; report anything pre-existing it finds outside that scope rather than
silently fixing unrelated history.

## 5. Report

Structure the output as:
- **✅ Aligned** — what this session changed and confirmed consistent (repo ↔ live, docs ↔ reality).
- **⚠️ Drift found** — exact file/location and what's wrong. Fix it directly if it's unambiguous
  (a stale version number, a missing doc update for something this session already decided). Flag
  it instead of fixing if it requires a judgment call (e.g. which of two diverged versions is right).
- **🛑 Blocking** — anything that looks like it would regress live behaviour if left as-is (e.g. a
  dashboard HTML in the repo that's behind the live version and about to be redeployed from). Stop
  and say so before any deploy step, don't deploy and then find out.

Never commit, push, or deploy anything from this skill on its own initiative — apply only the
unambiguous doc/repo-file fixes described above, and hand everything else back with a clear
recommendation.
