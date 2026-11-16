@echo off
REM run-notes — one command to start the meeting note taker. No code editing needed.
REM
REM Usage: run-notes
REM It watches your calendar, records meetings, and writes notes to notes\.
REM Press Ctrl+C to stop it.
REM First run sets everything up (takes a minute). Works on Windows.
setlocal
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo I couldn't find Python on this computer.
  echo Install Python 3.10 or newer from https://www.python.org/downloads/, then run this again.
  exit /b 2
)

if not exist .venv (
  echo First run: setting things up, this takes a minute...
  python -m venv .venv || (echo Couldn't create the setup folder. Check you have permission to write in this folder, then try again. & exit /b 2)
  call .venv\Scripts\activate.bat
  python -m pip install -q -r requirements.txt || (echo Couldn't install the needed parts. Check your internet connection and try again. & exit /b 2)
) else (
  call .venv\Scripts\activate.bat
  python -m pip install -q -r requirements.txt
)

echo Checking that Ollama is running on this laptop...
python -c "import requests; requests.get('http://127.0.0.1:11434/api/tags', timeout=5)" 2>nul
if errorlevel 1 (
  echo Ollama is not running. Start Ollama first, then run this again.
  echo The note taker only talks to Ollama on your own laptop.
  exit /b 2
)

echo Watching your calendar. Notes will land in notes\.
python calendar_watcher.py
