#!/usr/bin/env python3
"""Regenerate docs/tree-snapshot.json: the fallback file tree for the Pages explorer.

The explorer page (docs/index.html) loads the live tree from the GitHub API.
If that fails, it falls back to this snapshot. Re-run this script whenever the
tree changes and commit the result — never edit the snapshot by hand.

Usage: python3 scripts/generate-pages-snapshot.py
"""
import datetime
import json
import os

ROOTS = ("skills/made", "skills/liked", "tools/made", "tools/liked", "plugins")

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
files = []
for root in ROOTS:
    base = os.path.join(repo, root)
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = sorted(d for d in dirnames if d != "__pycache__")
        for name in sorted(filenames):
            if name.endswith(".pyc"):
                continue
            files.append(os.path.relpath(os.path.join(dirpath, name), repo).replace(os.sep, "/"))

snap = {
    "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "ref": "main",
    "files": sorted(files),
}
out = os.path.join(repo, "docs", "tree-snapshot.json")
with open(out, "w") as f:
    json.dump(snap, f, indent=2)
    f.write("\n")
print(f"Wrote {out}: {len(files)} files")
