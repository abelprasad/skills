# Setup on the Laptop (Windows)

Copy-paste steps for a Windows laptop. Takes about 10 minutes plus download time.

## 1. Get the pack onto the laptop

Download `codegraph-rtk-setup-pack.zip`, then unzip it to a folder, for example:

```
C:\codegraph-rtk\
```

You should see these inside: `install.ps1`, `install.sh`,
`skills-install.ps1`, `skills-install.sh`, a `skills/` folder,
`README.md`, `SETUP-ON-LAPTOP.md` (this file).

## 2. Open PowerShell in that folder

- Open File Explorer, go to `C:\codegraph-rtk\`
- Click the address bar, type `powershell`, press Enter.
  (Or open PowerShell, then `cd C:\codegraph-rtk`)

## 3. Allow the script (only if Windows blocks it)

If you get an execution-policy error, run this once (current user only, no admin):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

## 4. Run the installer

```powershell
.\install.ps1
```

A menu appears — pick `[1]` CodeGraph only, `[2]` RTK only, or `[3]` Both
(the default). It asks for confirmation before downloading anything.

If CodeGraph is chosen, the repo picker runs next — but it is optional.
The work laptop is work-only with no personal repos, so skipping is
normal there. Just press Enter at the prompt to skip it:

```
Point CodeGraph at repos? (optional, press Enter to skip. On a work laptop, skip this. You can run codegraph init later in any repo yourself.)
```

On a work laptop, skip it and run `codegraph init` yourself in the repo
you are working in. The installer never asks for company repo names,
paths, or URLs.

If you do opt in, the full picker is available (personal GitHub repos
only — company code stays out):

1. **Scan a parent folder:** type a folder like `C:\github` and it lists
   every folder with a `.git` directory. Pick all, or pick by number
   (e.g. `1 3`).
2. **Add repos one by one:** type a local path or a GitHub clone URL, one
   per line, blank line to finish. A URL is cloned first (default
   `C:\github\<repo>`, or a folder you type).

Example:

```
Scan a parent folder for repos? (e.g. C:\Users\you\github) [y/N]: y
Parent folder to scan [default C:\Users\you\github]: C:\github
Found 2 repos under C:\github:
  [1] C:\github\dogsrun
  [2] C:\github\clipsdaily-repo
Pick all (a), numbers separated by spaces (e.g. 1 3), or none (n) [default a]: a
Repo path or URL (blank to finish):
```

Each selected repo gets `codegraph init` and a per-repo PASS / FAIL line
with its file/node counts. Repos already initialized are skipped unless
you re-run with `-ReInit`.

No-prompt runs (same result, no menu):

```powershell
.\install.ps1 -All
.\install.ps1 -All -Repos "C:\github\dogsrun,https://github.com/you/repo"
.\install.ps1 -All -ScanRepos "C:\github"
.\install.ps1 -All -SkipRepos
```

What it does, in order:

1. Installs the CodeGraph CLI
2. Installs RTK via winget (`winget install rtk-ai.rtk`) — winget may ask for
   permission; accept it
3. Wires CodeGraph into Claude Code (`codegraph install --yes`)
4. Wires RTK into Claude Code (merges the PreToolUse hook into
   `%USERPROFILE%\.claude\settings.json`)
5. Runs the repo picker and `codegraph init` per selected repo (CodeGraph only)
6. Runs the Skills step — detects the AI setups on the machine (Claude
   Code, Cursor, Copilot, Codex, Gemini CLI, OpenCode) and offers the
   bundled skills. See "Skills step" below.
7. Prints both versions, the `rtk gain` dashboard, and a PASS / SKIP / FAIL table

Expected output at the end: `codegraph --version` prints a version like
`1.6.2`, `rtk --version` prints a version like `1.2.0`, and the script prints
"Done."

## Skills step

After the tools install, the installer finds the AI setups on the machine
and asks which skills to install into them. It prints DETECTED / not found
per setup with the path checked. A setup that is not detected is skipped —
no folder is created for it.

One menu lists each skill with a one-line description — pick all, pick by
number, or skip:

```
  [1] i-have-adhd - ADHD output protocol: action first, numbered steps, no preamble
  [2] local-ponytail - Laziest working solution: YAGNI, stdlib first, one line before fifty
  [3] summary - /summary: six-section handoff of everything talked and done
  [4] repo-packaging - ADRs, CLI product, privacy rule, dev-copy rule, presence
  [5] qa-agent - Checklist QA with screenshots + HTML report
  [6] local-ui-ux-pro-max - Design bundle: shadcn + Tailwind, brand, banners, slides
  [a] All bundled skills (default)
  [s] Skip skills
Optional external installs (never in All — pick by number only):
  [7] claude-mem - Persistent memory across sessions (external, needs Node.js)
  [8] security-audit - Multi-phase security audit skill (external, needs Node.js)
```

The step also prints whether CodeGraph and RTK are installed, so one menu
covers tools + skills. Bundled skills ship in the pack under `skills/`
(offline, exact versions Abel already uses). Optional external installs
are opt-in only and each asks for confirmation first: **claude-mem**
(`npx claude-mem install --setup defer`; setup deferred to first session;
observer trial asks for a payment method) and **security-audit** (`npx
skills add https://github.com/cloudflare/security-audit-skill --skill
security-audit --global`). Both need Node.js.

No-prompt runs: `.\install.ps1 -All -SkillsAll` (all bundled skills),
`.\install.ps1 -All -SkillsSkip` (skip), `.\install.ps1 -All -Skills
"claude,cursor"` (those setups only).

## 5. Restart your agent

Close and reopen Claude Code (or Cursor / Copilot / whichever agent you use)
so it picks up the new MCP server and hook.

## 6. Index your first project

```powershell
cd <your-project>
codegraph init
codegraph status
codegraph explore "how does auth work"
rtk gain
```

`codegraph init` is once per project. It creates a local `.codegraph/`
directory in that project — do not commit it.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `codegraph` / `rtk` not recognized after install | Close PowerShell and open a new one (PATH updates need a fresh shell) |
| winget not found | Install "App Installer" from the Microsoft Store, then re-run |
| `rtk gain` says "No hook installed" | Check `%USERPROFILE%\.claude\settings.json` has a `PreToolUse` entry with command `rtk hook claude`, then restart the agent |
| `codegraph install` hangs | It prompts when run without `--yes`. This pack runs it with `--yes`; if it still hangs, kill it and run `codegraph install --yes` yourself in a fresh terminal |
| Execution policy error | See step 3 above |

## Linux / macOS

Same pack, other script: `bash install.sh` — same menu, same repo picker,
same flags (`--all`, `--codegraph-only`, `--rtk-only`, `--yes`,
`--repos <csv>`, `--scan-repos <dir>`, `--reinit`, `--skip-repos`).
Everything else (wiring, verification, `codegraph init` per project) is
identical.
