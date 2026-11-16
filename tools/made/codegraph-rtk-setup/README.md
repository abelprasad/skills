# CodeGraph + RTK Setup Pack

Two tools that make an agent (and you) understand a codebase like an architect,
while spending far fewer tokens doing it. Both are 100% local, single-machine
tools. Nothing in this pack is tied to one repo, one company, or one machine —
run it on any capable device; only the installer differs by OS.

## What it installs

| Tool | What it does | License |
| --- | --- | --- |
| **CodeGraph** ([colbymchenry/codegraph](https://github.com/colbymchenry/codegraph)) | Pre-indexed code knowledge graph. One query returns the relevant symbols, their source, and the call paths between them, instead of the agent grep-hunting file by file. Auto-syncs on every code change. Rust kernel. | MIT |
| **RTK** ([rtk-ai/rtk](https://github.com/rtk-ai/rtk)) | Rust CLI proxy that compresses shell output (git status/diff/log, test runs, ls/grep, builds) by 60–90% before it reaches agent context. Never blocks a command, never prints more than the raw output, and `rtk bypass <cmd>` runs anything unfiltered. | Apache 2.0 |

They do different jobs: CodeGraph is the architect brain (what the code means),
RTK is the cost saver (cheaper for the agent to read command output).

## How to run

One command, then pick from a menu, like the Claude Code installer:

### Linux / macOS

```bash
bash install.sh
```

### Windows (PowerShell)

```powershell
.\install.ps1
```

If Windows blocks the script, run this first (current user only):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

The menu:

```
=== CodeGraph + RTK setup ===

  [1] CodeGraph only   - code knowledge graph for your agents
  [2] RTK only         - compress shell output before agent context
  [3] Both (default)   - CodeGraph + RTK
  [4] Quit
```

It asks for confirmation before downloading anything, shows progress per
tool, and prints a PASS / SKIP / FAIL table at the end.

### Repo picker (when CodeGraph is chosen)

Work laptop = work only, no personal repos on it. The repo step is
**optional and skipped by default** — at the prompt, press Enter to skip:

```
Point CodeGraph at repos? (optional, press Enter to skip. On a work laptop, skip this. You can run codegraph init later in any repo yourself.)
```

On a work laptop, skip it and run `codegraph init` yourself in the repo
you are working in. Do not paste repo names or paths here. The installer
never asks for company repo names, paths, or URLs, and never clones
anything unless you opt in and give it a URL yourself.

If you do opt in, the picker offers two ways:

1. **Scan a parent folder:** give a folder like `~/github` or `C:\github`
   and it lists every folder with a `.git` directory. Pick all, or pick
   by number (e.g. `1 3`).
2. **Add repos one by one:** type a local path, one per line, blank line
   to finish. On a personal machine you can also type a GitHub clone URL
   and it is cloned first (default target `~/github` or `C:\github`, or a
   folder you type).

Example (personal machine):

```
Scan a parent folder for repos? (e.g. ~/github) [y/N]: y
Parent folder to scan [default ~/github]: ~/github
Found 2 repos under ~/github:
  [1] /home/you/github/dogsrun
  [2] /home/you/github/clipsdaily-repo
Pick all (a), numbers separated by spaces (e.g. 1 3), or none (n) [default a]: a
Repo path or URL (blank to finish):
```

Each selected repo gets `codegraph init` and a per-repo PASS / FAIL line
with its file/node counts. Repos already initialized are skipped unless
you re-init. You can also index a project any time by hand:

```bash
cd <your-project>
codegraph init
```

The full picker stays available whenever you opt in: folder scan,
individual paths, and GitHub clone URLs (a URL is cloned first, then
initialized). Nothing is removed — skipping is just the default on a work
laptop with no personal repos.

### Automation (no prompts)

```bash
bash install.sh --all                                        # both, no prompt
bash install.sh --codegraph-only                             # CodeGraph only
bash install.sh --rtk-only                                   # RTK only
bash install.sh --all --yes                                  # both, skip the download confirm
bash install.sh --all --repos ~/github/dogsrun,https://github.com/you/repo
bash install.sh --all --scan-repos ~/github                  # scan a folder, init all repos found
bash install.sh --all --reinit                               # re-init repos already indexed
bash install.sh --all --skip-repos                           # skip the repo step entirely
```

```powershell
.\install.ps1 -All
.\install.ps1 -CodeGraphOnly
.\install.ps1 -RTKOnly
.\install.ps1 -All -Yes
.\install.ps1 -All -Repos "C:\github\dogsrun,https://github.com/you/repo"
.\install.ps1 -All -ScanRepos "C:\github"
.\install.ps1 -All -ReInit
.\install.ps1 -All -SkipRepos
```

Both installers do the same steps: install the CLIs, wire both into
Claude Code (CodeGraph as an MCP server, RTK as a PreToolUse hook on Bash),
optionally initialize your repos, then verify versions and print next steps.

### Skills step (runs after the tools)

After the tools install, the installer offers a Skills step: it finds the
AI setups on the machine and installs bundled skills into them. One menu
covers tools + skills — the step also prints whether CodeGraph and RTK are
installed, so you can see the whole setup at a glance.

It detects (never assumes) each setup and prints DETECTED / not found with
the path checked:

| Setup | Skills folder | How it is detected |
| --- | --- | --- |
| Claude Code | `~/.claude/skills` | `~/.claude` exists, or `claude` on PATH |
| Cursor | `~/.cursor/skills` | `~/.cursor` exists, or `cursor` on PATH |
| GitHub Copilot | `~/.copilot/skills` | `~/.copilot` exists, or `copilot` on PATH |
| Codex | `~/.agents/skills` | `~/.agents` / `~/.codex` exists, or `codex` on PATH (legacy `~/.codex/skills` used only if it already exists) |
| Gemini CLI | `~/.gemini/skills` | `~/.gemini` exists, or `gemini` on PATH |
| OpenCode | `~/.config/opencode/skills` | `~/.config/opencode` exists, or `opencode` on PATH |
| Local (shared) | `~/.agents/skills` | folder exists, or Codex / Cursor / Gemini detected (same folder as Codex, installed once) |

A setup that is not detected is reported SKIP — no directory is ever
created for it. VS Code project skills live in `.github/skills` inside
each repo and are not covered by this machine-wide install.

The Skills menu lists each skill with a one-line description. Pick all,
pick by number, or skip:

```
Which skills? (i-have-adhd first; the rest are Abel's own skills.)
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

Bundled skills ship in the pack under `skills/` (offline, exact versions
Abel already uses — see `skills/README.md`). Each selected skill is copied
whole into `<setup-skills>/<skill-name>/` and verified with a PASS / FAIL
line per skill per setup. The `local-ui-ux-pro-max` skill includes its
`cli/` sub-skills (4.8 MB), which its router SKILL.md points at.

Optional external installs (opt-in only, each asks for confirmation first):

- **claude-mem** — `npx claude-mem install --setup defer`. Persistent
  memory across sessions. Needs Node.js. Setup is deferred to your first
  session, so no browser sign-in happens during install — but the observer
  trial asks for a payment method when you do sign in, and memory lives in
  `~/.claude-mem`. Source: thedotmack/claude-mem (Apache-2.0).
- **security-audit** — `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global`.
  Multi-phase security audit skill. Needs Node.js. Source:
  cloudflare/security-audit-skill (MIT). Both commands were verified from
  their READMEs Nov 16, 2026.

Automation for the Skills step:

```bash
bash install.sh --all --skills-all                                  # all bundled skills, all detected setups
bash install.sh --all --skills-skip                                 # skip the Skills step
bash install.sh --all --skills claude,cursor                        # skills into those setups only
bash install.sh --all --skill-names i-have-adhd,summary             # only those skills
bash install.sh --all --skills-all --include-claude-mem --include-security-audit  # + opt-in externals
```

```powershell
.\install.ps1 -All -SkillsAll
.\install.ps1 -All -SkillsSkip
.\install.ps1 -All -Skills "claude,cursor"
.\install.ps1 -All -SkillNames "i-have-adhd,summary"
.\install.ps1 -All -SkillsAll -IncludeClaudeMem -IncludeSecurityAudit
```

In non-interactive mode with no skills flags, the Skills step is skipped
with a note — re-run with `-SkillsAll` / `--skills-all` to install.

## After install

Restart your agent, then index one project at a time:

```bash
cd <your-project>
codegraph init        # builds the graph once; auto-syncs after that
codegraph status      # index stats: files, symbols, edges
```

Use it:

```bash
codegraph explore "how does auth work"      # symbols + source + call paths, one shot
codegraph query <symbol>                    # find a symbol
codegraph callers <symbol>                  # who calls it
codegraph callees <symbol>                  # what it calls
codegraph impact <symbol>                   # blast radius of changing it
codegraph affected                          # test files affected by your changes
rtk gain                                    # tokens saved so far
rtk git status                              # compressed git status (the hook does this automatically in Claude Code)
```

## Verify it worked

```
codegraph --version     # e.g. 1.6.2 (version floats to latest at install time)
rtk --version           # e.g. 1.2.0
rtk gain                # shows the savings dashboard; "No hook installed" means the Claude Code hook step needs a retry
codegraph status        # run inside an initialized project
```

## Notes

- **Local only.** CodeGraph indexes on your machine. Telemetry is anonymous
  usage stats only (no code, paths, or names) — turn it off with
  `codegraph telemetry off` or `CODEGRAPH_TELEMETRY=0`.
- **RTK never hides output.** Anything it cuts tells you where the full
  version is, and the command's exit code passes through unchanged.
- **Per project, not per machine.** `codegraph init` is run once per repo.
  It creates a local `.codegraph/` directory in that repo. Do not commit it.
- **Uninstall.** `codegraph uninstall` removes the agent wiring;
  `codegraph uninit` removes a project's index. RTK: remove the PreToolUse
  hook from `~/.claude/settings.json` (or `%USERPROFILE%\.claude\settings.json`)
  and delete the binary.
- **Versions at pack time (Nov 16, 2026):** CodeGraph 1.6.2, RTK 1.2.0,
  verified working on a Linux host. The installers always pull latest, so
  your version may be newer.

## Still unproven

- The Windows `install.ps1` has never been executed (built and syntax-checked
  on Linux; first real run is on a Windows machine).
- `rtk gain` numbers only become meaningful after a week of real use; the
  first-run dashboard will show near-zero savings.
- CodeGraph's own benchmark caveat: in long multi-turn sessions its dense
  answers leave more retrieval context resident than a grep-and-read agent
  (their measurement: ~67k vs ~18k tokens on VS Code). If a session feels
  heavy, start a fresh one.
