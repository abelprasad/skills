# Install

Two ways in. Plugin install is recommended; copy-install is for every other harness.

## Plugin install (Claude Code, recommended)

Inside a Claude Code session:

```
/plugin marketplace add abelprasad/skills
/plugin install <plugin>@abelprasad
```

Or in one command (Claude Code 2.1.275+):

```
/plugin install <plugin> --marketplace abelprasad/skills
```

Plugins (one per vendored skill):

| Plugin | Skill |
| --- | --- |
| `local-ponytail` | Laziest working solution |
| `summary` | `/summary` handoff (slash command included) |
| `repo-packaging` | Package a repo like a product |
| `qa-agent` | Checklist QA (`/qa-test` slash command included) |
| `check-owned-before-recommending` | Check owned items before recommending |
| `flagged-board-submit-handoff` | Flagged job board handoff |
| `screenshot-guided-portal-filing` | Screenshot-guided portal filing |
| `i-have-adhd` | ADHD output protocol |
| `local-ui-ux-pro-max` | Design bundle |
| `ffmpeg-skill` | ffmpeg recipes |
| `motion-design` | Motion design principles |
| `unslop` | Unslop a screen |

## Copy-install (every harness)

```sh
bash scripts/install.sh --all        # macOS / Linux
.\scripts\install.ps1 -All           # Windows
```

Installs every vendored skill (`skills/made/` plus the vendored folders in `skills/liked/`) into each detected harness. A harness is detected when its skills folder exists on the machine; nothing is ever created for a harness that isn't there.

Harness paths (verified Nov 16, 2026):

| Harness | Skills folder |
| --- | --- |
| Claude Code | `~/.claude/skills` |
| Cursor | `~/.cursor/skills` (also reads `~/.agents/skills`) |
| GitHub Copilot | `~/.copilot/skills` |
| Codex | `~/.agents/skills` (legacy `~/.codex/skills` only if it already exists) |
| Gemini CLI | `~/.gemini/skills` |
| OpenCode | `~/.config/opencode/skills` |
| Local (shared) | `~/.agents/skills` (same folder as Codex, deduped) |

Pick skills by name instead of all:

```sh
bash scripts/install.sh --skills local-ponytail,summary,i-have-adhd
.\scripts\install.ps1 -Skills local-ponytail,summary,i-have-adhd
```

List what would install, without installing:

```sh
bash scripts/install.sh --list
.\scripts\install.ps1 -List
```

## Tools

Each tool in `tools/made/` installs itself — read its own README. In short:

- `note-taker`: copy the folder to the work laptop, fill in `config.yaml`, run `run-notes.bat`.
- `standup-notes`: copy the folder, fill in `config.yaml`, run `standup.bat`.
- `dependency-watch`: copy the folder, fill in `config.yaml`, run `register-watch.bat` (needs Admin, weekly Monday 08:00).
- `qa-agent`: copy the folder, run `run-qa.bat <site-url> <checklist.yaml>`.
- `codegraph-rtk-setup`: run `install.ps1` (Windows) or `install.sh` (Linux/macOS), pick from the menu.
- `work-laptop-local-ai`: run `setup-local-ai.ps1`, pick from the menu.
- `agent-worktree`: copy `agent-worktree.sh` to `~/agent-worktree.sh`, read `WORKTREES.md`.

## Requirements

- Git, for the clone.
- Claude Code 2.1+ for the plugin route.
- Python 3.10+ for the note taker, standup notes, dependency watch, and QA agent.
- Node.js for the optional external installs (claude-mem, security-audit).
- Windows + Outlook for the note taker's live calendar mode; `.ics` fallback works anywhere.
