@echo off
REM run-qa — one command to run a QA checklist. No code editing needed.
REM
REM Usage:   run-qa <website-address> <checklist-file>
REM Example: run-qa https://the-internet.herokuapp.com checklists\example-checklist.yaml
REM
REM First run sets everything up (takes a minute). After that, just run the
REM command again. The report opens by itself when the run finishes.
setlocal
if "%~2"=="" (
  echo Usage: run-qa ^<website-address^> ^<checklist-file^>
  echo Example: run-qa https://the-internet.herokuapp.com checklists\example-checklist.yaml
  exit /b 2
)
cd /d "%~dp0"
where python >nul 2>nul || (
  echo I couldn't find Python on this computer.
  echo Install it from https://www.python.org/downloads/ and tick "Add python.exe to PATH", then run this again.
  exit /b 2
)
if not exist .venv (
  echo First run: setting things up, this takes a minute...
  python -m venv .venv || (
    echo Couldn't create the setup folder. Check you have permission to write in this folder, then try again.
    exit /b 2
  )
  call .venv\Scripts\activate.bat
  python -m pip install -q -r requirements.txt || (
    echo Couldn't install the needed parts. Check your internet connection and try again.
    exit /b 2
  )
  python -m playwright install chromium || (
    echo I couldn't download a browser automatically.
    echo If the run can't start a browser, install Google Chrome and set QA_CHROME_PATH to where chrome.exe lives, or run: python -m playwright install chromium
  )
) else (
  call .venv\Scripts\activate.bat
  python -m pip install -q -r requirements.txt
)
echo Running the checks, this usually takes a minute...
python qa_runner.py --checklist "%~2" --site "%~1" --out out
set EXITCODE=%ERRORLEVEL%
echo.
if %EXITCODE%==0 (
  echo All checks passed.
) else (
  echo Some checks failed. The report below shows what went wrong.
)
echo Report: out\report.html
start "" "out\report.html"
exit /b %EXITCODE%
