@echo off
REM Dependency Watch — register the weekly scheduled task (Monday 08:00).
REM The task runs run-watch.bat in this folder, then exits. Nothing stays open.
REM Kill switch: run unregister-watch.bat.
REM
REM Usage:
REM   register-watch.bat              register the task, runs the Python check directly
REM   register-watch.bat --use-claude register the task, runs it via Claude Code (claude -p)
REM   register-watch.bat --dry-run    print the command that would be registered, change nothing
setlocal
set "TASKNAME=DependencyWatch"
set "SCRIPT=%~dp0run-watch.bat"

if "%~1"=="--dry-run" (
  echo DRY RUN — nothing was registered. The command would be:
  echo schtasks /create /tn "%TASKNAME%" /tr "\"%SCRIPT%\"" /sc weekly /d MON /st 08:00 /f
  exit /b 0
)

if "%~1"=="--use-claude" (
  where claude >nul 2>nul
  if %errorlevel% neq 0 (
    echo Claude Code (claude) was not found on PATH. Install it first, or run register-watch.bat without --use-claude.
    exit /b 1
  )
  echo Registering %TASKNAME% to run via Claude Code every Monday at 08:00...
  schtasks /create /tn "%TASKNAME%" /tr "claude -p \"run dependency watch from %~dp0config.yaml and report only what changed since the baseline\"" /sc weekly /d MON /st 08:00 /f
  if %errorlevel% neq 0 (
    echo The task could not be registered. Try running this file as Administrator.
    exit /b 1
  )
  echo Registered: %TASKNAME% runs every Monday at 08:00 via Claude Code.
  echo To stop it, run unregister-watch.bat.
  exit /b 0
)

echo Registering %TASKNAME% to run every Monday at 08:00...
schtasks /create /tn "%TASKNAME%" /tr "\"%SCRIPT%\"" /sc weekly /d MON /st 08:00 /f
if %errorlevel% neq 0 (
  echo The task could not be registered. Try running this file as Administrator.
  exit /b 1
)
echo Registered: %TASKNAME% runs every Monday at 08:00.
echo To stop it, run unregister-watch.bat.
endlocal
