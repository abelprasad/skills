#!/bin/sh
# Standup notes — one command.
# Reads your local git log and drafts Yesterday / Today / Blockers.
# Nothing is sent anywhere. Edit config.yaml once, then just run this.
cd "$(dirname "$0")" || exit 1
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is not installed. Install it, then run this again."
  exit 1
fi
python3 standup.py "$@"
