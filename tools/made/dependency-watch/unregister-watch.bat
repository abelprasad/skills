@echo off
REM Dependency Watch — kill switch. Removes the weekly scheduled task.
REM Your reports in out\ are kept; only the schedule is stopped.
schtasks /delete /tn "DependencyWatch" /f
if %errorlevel% equ 0 (
  echo Stopped. Dependency Watch will not run on schedule anymore.
) else (
  echo No scheduled task named DependencyWatch was found. Nothing to stop.
)
