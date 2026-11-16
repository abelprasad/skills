# qa-agent — QA checklist agent

A small tool that checks a website for you, following a checklist you write
in plain words. It opens the site, clicks through the steps, takes a
screenshot of each step, and writes a report you can open in your browser.
If something fails, the report shows it in red, in plain English, with a
screenshot of what the page looked like.

No coding needed to use it. The example checklist tests a public demo
website. Swap in your own checklist to test a real site. Nothing in this
folder is company-specific.

## Start here — no coding needed

You only need two things: this folder, and Python (free). It works on
Windows, macOS, and Linux — the steps are the same on all three, except
where noted.

### 1. Install Python (once)

- **Windows:** download it from https://www.python.org/downloads/ and run
  the installer. On the first screen, tick the box that says
  **"Add python.exe to PATH"**, then click Install.
- **macOS:** download it from the same page, or run `brew install python`
  if you already use Homebrew.
- **Linux:** it is usually already there. If not, use your package manager,
  e.g. `sudo apt install python3 python3-venv` (Ubuntu/Debian).

To check it worked, open a terminal (Windows: search for "Command Prompt";
macOS: search for "Terminal") and type `python --version`. You should see a
version number like `Python 3.12`.

### 2. Get this folder

Download or copy the `qa-agent` folder onto your computer. No install step,
no accounts, no keys.

### 3. Run one command

Open a terminal in the `qa-agent` folder and run:

- **Windows:** `run-qa https://the-internet.herokuapp.com checklists\example-checklist.yaml`
- **macOS / Linux:** `bash run-qa.sh https://the-internet.herokuapp.com checklists/example-checklist.yaml`

That is the whole command: the website address, then the checklist file.
The first run sets everything up (about a minute). After that, just run the
command again whenever you want a fresh check.

### 4. Read the report

When the run finishes, the report opens by itself in your browser. It lives
at `out/report.html` inside the folder. It says how many checks passed and
failed, and each check has a screenshot and, if it failed, a plain-English
explanation of what went wrong. To share it, copy the whole `out/` folder —
the report opens on any computer, no server needed.

**What to expect:** a browser window opens briefly while the checks run
(you will see the pages flash by), then closes itself. A normal run takes
about a minute.

## Write your own checklist

A checklist is a plain text file that says what to check, in order. Open
`checklists/example-checklist.yaml` — every line is explained in the
comments at the top of the file. To make your own:

1. Copy `checklists/example-checklist.yaml` to a new file, e.g.
   `checklists/my-site.yaml`.
2. Change the `site:` line to your website address.
3. Rewrite the steps in the same format. Each step is a plain-English
   name plus one action: open a page, click something, type into a box, or
   check that some words or a button show up.
4. Run it: `run-qa https://your-website checklists\my-site.yaml`
   (use `bash run-qa.sh ...` on macOS/Linux).

If you are unsure how to point at a button or a box, ask a developer for
the right `selector:` — that is the only technical bit, and it is one line
per step.

**Passwords:** never put a real password in a checklist file. For a step
that needs a secret, use `value_env: MY_PASSWORD_SETTING` and set that
setting on your computer first. The runner fails the step loudly if the
setting is missing.

## Works on any computer

The core flow is identical everywhere: Python + Playwright + one command.
The only things that differ by system are noted here:

| | Windows | macOS | Linux |
|---|---|---|---|
| Run it | `run-qa <site> <checklist>` | `bash run-qa.sh <site> <checklist>` | `bash run-qa.sh <site> <checklist>` |
| Install Python | python.org installer (tick "Add to PATH") | python.org or `brew install python` | usually pre-installed |
| Browser | downloaded automatically on first run, or use installed Chrome via `QA_CHROME_PATH` | same | same |
| Run it on a schedule | Task Scheduler | launchd | cron |
| Open the report | opens by itself | opens by itself | opens by itself (`xdg-open`) |

No hardcoded paths, no machine-specific setup. The only requirement is
Python 3.10 or newer and a browser (downloaded automatically, or an
installed Chrome pointed to with `--executable-path` / `QA_CHROME_PATH`).

If `playwright install chromium` is blocked by a company proxy, use a
browser you already have: `run-qa` accepts it through the `QA_CHROME_PATH`
setting, or run the Python command directly with
`--executable-path "C:\Program Files\Google\Chrome\Application\chrome.exe"`.

## For developers

### Quickstart

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
playwright install chromium
python qa_runner.py --checklist checklists/example-checklist.yaml
```

### The command

```
/qa-test <site-url> <checklist.yaml> [--out <report-dir>]
```

See `commands/qa-test.md` for the slash-command doc and
`skills/qa-agent/SKILL.md` for the full agent workflow. The runner also
accepts `--timeout-ms`, `--headed`, and `--executable-path` (or
`QA_CHROME_PATH`). It reads the standard proxy env vars (`HTTPS_PROXY`,
`NO_PROXY`) so it works behind a corporate proxy.

### Offline smoke test

No network needed. Serve the local fixture pages and run the fixture
checklist, which mirrors the example step-for-step:

```bash
python -m http.server 8471 --directory fixtures &
python qa_runner.py --checklist checklists/fixture-checklist.yaml --out out-fixture
```

Then open `out-fixture/report.html`.

### The loop

One run is a manual command. The loop is the trigger plus where the report
lands. Three options, same runner in all three:

1. **Manual (default).** Run the command whenever you want a run.
2. **Nightly.** Windows Task Scheduler runs `run-qa <site> <checklist>` at a
   fixed time and copies `out/` to a shared folder. macOS: launchd.
   Linux: the same command in a cron job.
3. **On deploy.** A deploy hook or CI job runs the command after each QA
   deploy and posts the report link (shared folder, Teams, or email).

Pick one trigger per checklist. A failed step never stops the run, and a
failing run exits non-zero, so schedulers and CI can alert on it.

### Layout

```
run-qa.bat                    one command (Windows)
run-qa.sh                     one command (macOS / Linux)
qa_runner.py                  the runner (checklist -> browser -> report)
skills/qa-agent/SKILL.md      the agent skill (workflow + rules)
commands/qa-test.md           the /qa-test slash command
checklists/example-checklist.yaml   fake example, public demo site only
checklists/fixture-checklist.yaml   offline fixture version of the example
fixtures/demo.html, ab.html   local pages for the offline test
templates/report.html         the HTML report template
requirements.txt              playwright + pyyaml
out/                          generated reports (gitignored)
```

### Rules

- The checklist is data. The runner never edits it.
- Every step gets a screenshot, pass or fail.
- A step that was not executed is `not run`, never `pass`.
- No secrets in checklists, reports, or the repo. Env vars only.
- Error messages are plain English with a next step; the technical detail
  stays in the report in small print for developers.
