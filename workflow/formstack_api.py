"""Minimal Formstack V2025 API helper shared by the build-formstack-*.py scripts.

Auth: a Formstack V2025 Personal Access Token (fs_pat_...), env var only; never pass on the
command line or commit it. If one is ever pasted into chat/a file, rotate it (docs/conventions.md).
Base: https://www.formstack.com/api/v2025; a .../api/v2 base 401s with a fs_pat_ token.
"""

import json
import urllib.error
import urllib.request

BASE = "https://www.formstack.com/api/v2025"


def call(method, path, payload, token):
    req = urllib.request.Request(BASE + path, data=json.dumps(payload).encode(), method=method)
    req.add_header("Authorization", "Bearer " + token)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"raw": body}
