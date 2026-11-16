#!/usr/bin/env bash
# run-qa — one command to run a QA checklist. No code editing needed.
#
# Usage:   run-qa <website-address> <checklist-file>
# Example: run-qa https://the-internet.herokuapp.com checklists/example-checklist.yaml
#
# First run sets everything up (takes a minute). After that, just run the
# command again. The report opens by itself when the run finishes.
# Works on macOS and Linux. On Windows, use run-qa.bat instead.
set -u

if [ $# -lt 2 ]; then
  echo "Usage: run-qa <website-address> <checklist-file>"
  echo "Example: run-qa https://the-internet.herokuapp.com checklists/example-checklist.yaml"
  exit 2
fi

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
  python -m playwright install chromium || echo "Note: I couldn't download a browser automatically. If the run can't start a browser, install Google Chrome and set QA_CHROME_PATH to its location, or run: python -m playwright install chromium"
else
  # shellcheck disable=SC1091
  . .venv/bin/activate
  python -m pip install -q -r requirements.txt
fi

echo "Running the checks, this usually takes a minute..."
code=0
python qa_runner.py --checklist "$2" --site "$1" --out out || code=$?
echo
if [ "$code" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed. The report below shows what went wrong."
fi
echo "Report: out/report.html"
# Open the report in the default browser (best effort, silent on machines
# with no browser, e.g. a headless server). xdg-open first: on Linux the
# bare `open` command is an unreliable wrapper.
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open out/report.html >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open out/report.html >/dev/null 2>&1 || true
fi
exit "$code"
