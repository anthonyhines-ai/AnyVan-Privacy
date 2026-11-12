#!/usr/bin/env python3
"""Repo consistency check for AnyVan-Privacy.

Catches the exact drift classes found in the 2026-11-11 full project sweep, mechanically,
instead of relying on someone remembering to check:
  1. CLAUDE.md's documented file tree vs. what's actually on disk (top-level dirs).
  2. Every AVDashboard.runQuery('name', ...) call in a dashboard HTML has a matching
     repo SQL file (by name, hyphen/underscore-normalised).
  3. Every markdown file under a PII-bearing folder starts with the required
     CONFIDENTIAL/PII or INTERNAL banner (this repo's own house style rule).
  4. A secret-pattern scan, including the Twilio Account SID pattern this repo's own
     CLAUDE.md specifically calls out as a push-protection trigger.

Run from the repo root: python3 scripts/check_consistency.py
Exit code is non-zero iff any finding was printed, so it can gate a commit/CI step.
No third-party dependencies, no network calls -- static checks only. It cannot see what's
actually live on AV Dashboards or the workflow-system; that needs a live comparison
(see the session-alignment-check skill for that).
"""
import os
import re
import subprocess
import sys

REPO_ROOT = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
).stdout.strip()
os.chdir(REPO_ROOT)

TRACKED = subprocess.run(
    ["git", "ls-files"], capture_output=True, text=True, check=True
).stdout.splitlines()

findings = []

# Folders whose markdown files must carry a CONFIDENTIAL/PII or INTERNAL banner, per
# CLAUDE.md's "Records house style". templates/ is excluded -- those are skeletons, not
# records. Add a new topic subfolder here when CLAUDE.md gains one.
PII_BANNER_FOLDERS = (
    "booking-lookups/",
    "communication-lookups/",
    "call-recording-delivery/",
    "interaction-hub/",
    "handoffs/",
    "retention/",
)
BANNER_MARKERS = ("CONFIDENTIAL", "INTERNAL")


def norm_query_name(s):
    return re.sub(r"[-_]+", "_", s.strip().lower())


# ---------- 1. CLAUDE.md file tree vs. disk ----------
def check_claude_md_tree():
    claude_md = "CLAUDE.md"
    if claude_md not in TRACKED:
        return
    text = open(claude_md, encoding="utf-8").read()
    m = re.search(r"## Layout\s*```(.*?)```", text, re.DOTALL)
    if not m:
        findings.append(f"{claude_md}: couldn't find a fenced layout block under '## Layout' -- check manually.")
        return
    tree_block = m.group(1)
    documented_top = set()
    globs = set()
    for raw_line in tree_block.splitlines():
        line = raw_line.split("#", 1)[0].strip()  # strip trailing "# comment"
        if not line:
            continue
        # This layout block mixes single paths and "a.md · b.md · c.md"-style lines.
        for token in re.split(r"[·\s]+", line):
            token = token.strip()
            if not token:
                continue
            if token.startswith("*."):
                globs.add(token[1:])  # "*.html" -> ".html"
            else:
                documented_top.add(token.rstrip("/"))

    # Universal scaffolding files every repo has -- not worth requiring in a repo-specific
    # layout diagram, so never flag their absence.
    always_ok = {"CLAUDE.md", "README.md", "ONBOARDING.md"}

    actual_top = set()
    for f in TRACKED:
        if f.startswith("."):
            continue
        actual_top.add(f.split("/")[0])

    def covered(name):
        if name in documented_top or name in always_ok:
            return True
        return any(name.endswith(g) for g in globs)

    missing_from_docs = sorted(n for n in actual_top if not covered(n))
    missing_from_disk = sorted(d for d in documented_top if d not in actual_top and "/" not in d and "." not in d)
    if missing_from_docs:
        findings.append(
            f"{claude_md}: these top-level paths exist on disk but aren't in the documented layout: {missing_from_docs}"
        )
    if missing_from_disk:
        findings.append(
            f"{claude_md}: these top-level paths are documented but don't exist on disk any more: {missing_from_disk}"
        )


# ---------- 2. Dashboard query references vs. repo SQL files ----------
def check_dashboard_query_refs():
    html_files = [f for f in TRACKED if f.endswith(".html")]
    sql_files = [f for f in TRACKED if f.endswith(".sql")]

    known_names = {norm_query_name(os.path.basename(f)[:-4]) for f in sql_files}

    ref_pattern = re.compile(r"AVDashboard\.runQuery\(\s*['\"]([A-Za-z0-9_]+)['\"]")
    for f in html_files:
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                text = fh.read()
        except OSError:
            continue
        for name in set(ref_pattern.findall(text)):
            if norm_query_name(name) not in known_names:
                findings.append(
                    f"{f}: references query '{name}' via AVDashboard.runQuery(), but no matching "
                    f"*.sql file (by name) was found in the repo -- either the file is missing, "
                    f"or this query only ever existed on the platform."
                )


# ---------- 3. PII banner presence ----------
def check_pii_banners():
    for f in TRACKED:
        if not f.endswith(".md"):
            continue
        if not f.startswith(PII_BANNER_FOLDERS):
            continue
        if os.path.basename(f).startswith("METHODOLOGY"):
            # Reusable methodology docs are INTERNAL-by-default reference material, not
            # per-subject records -- still need a banner, just checked the same as anything else.
            pass
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                head = fh.read(400)
        except OSError:
            continue
        if not any(marker in head for marker in BANNER_MARKERS):
            findings.append(
                f"{f}: no CONFIDENTIAL/PII or INTERNAL banner found in the first ~400 characters -- "
                f"every record under {PII_BANNER_FOLDERS} must open with one, per CLAUDE.md's house style."
            )


# ---------- 4. Secret scan ----------
SECRET_PATTERNS = [
    (re.compile(r"sk_live_[A-Za-z0-9]{10,}"), "Stripe live secret key"),
    (re.compile(r"fs_pat_[A-Za-z0-9]{10,}"), "Formstack personal access token (rotate immediately per CLAUDE.md)"),
    (re.compile(r"xox[baprs]-\d{10,13}-\d{10,13}-[A-Za-z0-9]{24,}"), "Slack token"),
    (re.compile(r"\bAC[0-9a-f]{32}\b"), "Twilio Account SID -- replace with <TWILIO_ACCOUNT_SID> per CLAUDE.md"),
    (re.compile(r"AIza[0-9A-Za-z_-]{35}"), "Google API key"),
    (re.compile(r"-----BEGIN (RSA |EC )?PRIVATE KEY-----"), "private key block"),
]
SKIP_EXT = {".png", ".jpg", ".jpeg", ".gif", ".ico", ".xlsx", ".docx", ".pdf"}


def check_secrets():
    for f in TRACKED:
        if os.path.splitext(f)[1].lower() in SKIP_EXT:
            continue
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                for lineno, line in enumerate(fh, 1):
                    for pattern, label in SECRET_PATTERNS:
                        if pattern.search(line):
                            findings.append(f"{f}:{lineno}: possible {label} committed -- verify and rotate if real.")
        except OSError:
            continue


check_claude_md_tree()
check_dashboard_query_refs()
check_pii_banners()
check_secrets()

if findings:
    print(f"consistency check: {len(findings)} finding(s)\n")
    for f in findings:
        print(f"  - {f}")
    sys.exit(1)
else:
    print("consistency check: clean, no findings")
    sys.exit(0)
