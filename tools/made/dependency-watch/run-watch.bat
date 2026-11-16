@echo off
REM Dependency Watch — one-command manual run (Windows).
REM Reads config.yaml, checks the repo, writes a report to out\.
setlocal
cd /d "%~dp0"
where python >nul 2>nul
if %errorlevel% neq 0 (
  echo Python was not found on PATH. Install Python 3.10+ from python.org, then run this again.
  exit /b 1
)
python dependency-watch.py --config config.yaml
if %errorlevel% neq 0 (
  echo Dependency Watch finished with an error. See the message above.
  exit /b 1
)
echo Done. Report is in out\
endlocal
