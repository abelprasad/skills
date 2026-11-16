#!/usr/bin/env bash
# Dependency Watch — one-command manual run (macOS/Linux).
# Reads config.yaml, checks the repo, writes a report to out/.
set -e
cd "$(dirname "$0")"
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 was not found. Install Python 3.10+, then run this again."
  exit 1
fi
python3 dependency-watch.py --config config.yaml
echo "Done. Report is in out/"
