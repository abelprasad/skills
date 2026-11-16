#!/usr/bin/env bash
# run-notes — one command to start the meeting note taker. No code editing needed.
#
# Usage: run-notes
# It watches your calendar, records meetings, and writes notes to notes/.
# Press Ctrl+C to stop it.
# First run sets everything up (takes a minute). Works on macOS and Linux.
# On Windows, use run-notes.bat instead.
set -u
cd "$(dirname "$0")"

if ! command -v python3 >/dev/null 2>&1; then
  echo "I couldn't find Python on this computer."
  echo "Install Python 3.10 or newer from https://www.python.org/downloads/, then run this again."
  exit 2
fi

if [ ! -d .venv ]; then
  echo "First run: setting things up, this takes a minute..."
  python3 -m venv .venv || { echo "Couldn't create the setup folder. Check you have permission to write in this folder, then try again."; exit 2; }
  # shellcheck disable=SC1091
  . .venv/bin/activate
  python -m pip install -q -r requirements.txt || { echo "Couldn't install the needed parts. Check your internet connection and try again."; exit 2; }
else
  # shellcheck disable=SC1091
  . .venv/bin/activate
  python -m pip install -q -r requirements.txt
fi

echo "Checking that Ollama is running on this laptop..."
if ! python -c "import requests; requests.get('http://127.0.0.1:11434/api/tags', timeout=5)" 2>/dev/null; then
  echo "Ollama is not running. Start Ollama first, then run this again."
  echo "The note taker only talks to Ollama on your own laptop."
  exit 2
fi

echo "Watching your calendar. Notes will land in notes/."
python calendar_watcher.py
