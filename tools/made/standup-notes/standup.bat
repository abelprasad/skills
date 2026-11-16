@echo off
REM Standup notes — one command.
REM Reads your local git log and drafts Yesterday / Today / Blockers.
REM Nothing is sent anywhere. Edit config.yaml once, then just run this.
cd /d "%~dp0"
where python >nul 2>nul
if %errorlevel% neq 0 (
  echo Python is not installed. Get it from python.org/downloads, then run this again.
  pause
  exit /b 1
)
python standup.py %*
if %errorlevel% neq 0 (
  echo.
  echo Something went wrong. Read the message above, fix it, run again.
  pause
  exit /b 1
)
pause
