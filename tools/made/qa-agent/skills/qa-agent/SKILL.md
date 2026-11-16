---
name: qa-agent
description: Test a QA site against a YAML checklist with Playwright, screenshot every step, and write a standalone HTML report. Use when asked to QA-test a site, run a checklist, verify a deploy, or produce a QA report.
---

# QA Agent

Run a checklist against a site, with a screenshot as evidence for every step, and produce an HTML report anyone can open.

## Workflow

1. **Read the checklist.** Load the YAML file passed to the run. A checklist is data: `name`, `site`, and an ordered list of `steps`. Never hardcode a site URL, a selector, or a credential into the skill or the runner. The checklist file is the only place site-specific facts live.
2. **Run it.** One command, no code editing: `run-qa <site-url> <checklist.yaml>` (Windows) or `bash run-qa.sh <site-url> <checklist.yaml>` (macOS/Linux). It sets up its own environment on first run, executes the steps in order with Playwright (Chromium, headless by default), and screenshots after every step, pass or fail. If `playwright install chromium` is blocked (corporate proxy), point it at a system browser instead: `--executable-path /path/to/chrome` or set `QA_CHROME_PATH`. Same flag works for a locally installed Chrome on any machine.
3. **Evaluate.** Each step records pass/fail, duration, a screenshot path, and error text. A failed step never stops the run: the remaining steps still execute so the report shows the full picture (a cascade after a failed navigation is itself useful evidence).
4. **Report.** The runner writes `out/report.html` from `templates/report.html` plus `out/screenshots/`. Open the report in any browser. Copy the whole `out/` folder to share it.
5. **Never invent a result.** A step that was not executed is marked `not run`, never `pass`. A step that errored is `fail` with the real error text. If the site is unreachable, the run fails and the report says so.

## Supported step actions

| Action | Fields | What it does |
|---|---|---|
| `goto` | `url` | Navigate to `url` (absolute, or relative to the checklist `site`) |
| `click` | `selector` | Click the element |
| `fill` | `selector`, `value` or `value_env` | Type into an input. `value_env` reads the value from an environment variable, never from the checklist file |
| `assert_text` | `selector`, `text` | Fail unless the element's text contains `text` |
| `assert_visible` | `selector` | Fail unless the element becomes visible |
| `assert_value` | `selector`, `value` | Fail unless an input's value equals `value` |
| `wait` | `ms` | Pause for `ms` milliseconds |

Selectors are Playwright selectors (CSS, `text=...`, `role=...`, etc.). Keep them as specific as the page allows, and prefer `text=` or `role=` over fragile positional selectors.

## Rules

- The checklist is data. Never edit the user's checklist for them; if a selector is wrong, report it as a failure and let them fix the file.
- Credentials and secrets live in environment variables only (`value_env`). Never write a password, token, or API key into a checklist, a report, or the repo.
- Every step needs a screenshot as evidence, pass or fail. A report without screenshots is incomplete.
- A fail goes loud: the report shows it red, with the error text and the screenshot. Passing steps stay quiet.
- Reports are standalone: inline CSS, screenshots by relative path. Anyone can open `out/report.html` with no server and no build step.
- Default timeout is 30s per step action. Slow first loads (cold QA environments) are normal; do not lower the timeout to make a run "pass".
- Do not run against production unless the checklist explicitly says the target is production. Default target is a QA/staging site.

## Built for non-technical users

A product owner, business analyst, or any worker must be able to use this
without dev skills. That is a design rule, not a nice-to-have:

- **One command.** `run-qa <site-url> <checklist.yaml>` is the whole
  interface. Site URL and checklist file are the only inputs. No code
  editing, no flags to memorize.
- **Plain-English checklist.** The example checklist explains every field
  in comments. A BA writes a checklist by copying it and changing the
  words. The only technical bit is `selector:`, and the comments say how to
  ask a developer for it.
- **Plain-English report.** Result per check is Passed/Failed, actions are
  named in plain words ("Open page", "Check words on the page"), and the
  summary is one sentence ("12 of 13 checks passed").
- **Plain-English errors.** Every error message says what happened in
  plain words and what to do next. The technical detail stays in the
  report in small print, for developers only.
- **Plain-English CLI errors.** A missing checklist file or a missing
  website address gets a message that says what is wrong and what to type
  next, never a bare traceback.

## Portable — any capable device

- The core flow is identical on Windows, macOS, and Linux: Python +
  Playwright + one command.
- No hardcoded OS paths, no machine-specific setup. The only requirement
  is Python 3.10+ and a browser (downloaded automatically, or an installed
  Chrome via `--executable-path` / `QA_CHROME_PATH`).
- Anything OS-specific (how to install Python, how to schedule a run)
  goes in the README's portability table, never baked into the runner or
  the checklists. The Windows entry point is `run-qa.bat`; macOS/Linux
  use `run-qa.sh`; both call the same `qa_runner.py` with the same
  arguments.

## The loop

One run is a task; the loop is the trigger plus the report delivery:

- **Manual (default):** `python qa_runner.py --checklist <file>` whenever you want a run.
- **Nightly:** Windows Task Scheduler (or cron on Linux) runs the same command at a fixed time and copies `out/` to a shared folder.
- **On deploy:** a deploy hook / CI job runs the command after each QA deploy and publishes the report link.

The trigger is the only part that changes between the three. The runner, the checklist format, and the report are identical in all three.
