---
description: Run the QA agent against a site using a checklist, and produce an HTML report with screenshots.
---

# /qa-test

Run a QA checklist against a site and produce an HTML report.

## Usage

```
/qa-test <site-url> <checklist.yaml> [--out <report-dir>]
```

- `<site-url>` — the site to test (overrides the `site` in the checklist file).
- `<checklist.yaml>` — path to the checklist. Use `checklists/example-checklist.yaml` for the demo run.
- `--out` — where the report and screenshots go. Default: `out/`.

## What it runs

For non-technical users, the one command is `run-qa` (Windows) or
`bash run-qa.sh` (macOS/Linux) — same two inputs, no other setup:

```
run-qa <site-url> <checklist.yaml>
```

For developers, the underlying command is:

```
python qa_runner.py --checklist <checklist.yaml> --site <site-url> --out <report-dir>
```

The runner executes the checklist steps in order with Playwright, screenshots every step, and writes `<report-dir>/report.html`.

## What it checks

- Every step in the checklist, in order: navigation, clicks, fills, text assertions, visibility assertions, value assertions.
- Each step records pass/fail, duration, a screenshot, and error text on failure.
- A failed step does not stop the run; the remaining steps still execute.

## What it never does

- Never edits the checklist. If a selector is wrong, it fails the step and reports it.
- Never writes credentials anywhere. Secrets come from environment variables only (`value_env`).
- Never invents a result. Unexecuted steps are `not run`, never `pass`.
- Never runs against production unless the checklist target is explicitly production.

## Example

```
/qa-test https://the-internet.herokuapp.com checklists/example-checklist.yaml
```

Then open `out/report.html`.
