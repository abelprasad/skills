# skills

One repo for everything Abel likes and makes: skills, tools, and plugins, in one place, installable in one go.

Built by [Abel Prasad](https://www.linkedin.com/in/abel-prasad) — [abelprasad.dev](https://abelprasad.dev)

Browse it: **[abelprasad.github.io/skills](https://abelprasad.github.io/skills/)** — a VS Code-style file explorer with per-file download, a download-everything button, and the one-command installer front and center. The tree loads live from the GitHub API, so it never drifts from the repo.

## What's in here

| Area | Count | What |
| --- | --- | --- |
| `skills/made/` | 7 | Skills Abel wrote himself |
| `skills/liked/` | 5 vendored, 6 linked | Skills Abel likes, vendored when the license permits, linked when it doesn't |
| `tools/made/` | 7 | Tools Abel built: scaffolds, setup packs, scripts |
| `tools/liked/` | 2 | Tools Abel likes: CodeGraph, RTK |
| `plugins/` | 12 | Claude Code plugins, one per vendored skill |
| `docs/adr/` | 6 | Architecture decisions, Nygard format |

## Skills Abel made

| Skill | One line |
| --- | --- |
| `local-ponytail` | Laziest working solution: YAGNI, stdlib first, one line before fifty. |
| `summary` | `/summary`: six-section handoff of everything talked and done. |
| `repo-packaging` | ADRs, CLI product, privacy rule, dev-copy rule, presence. |
| `qa-agent` | Checklist QA with screenshots and a plain-English HTML report. |
| `check-owned-before-recommending` | Check what Abel already owns before recommending a product. |
| `flagged-board-submit-handoff` | Spot a flagged job board and hand off fast with a cheat sheet. |
| `screenshot-guided-portal-filing` | File in a blocking portal with screenshots instead of driving it. |

## Skills Abel likes

Vendored (license permits it, files live in this repo):

| Skill | Source | License |
| --- | --- | --- |
| `i-have-adhd` | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | MIT |
| `local-ui-ux-pro-max` | UI/UX Pro Max bundle, v2.13.0 | MIT |
| `ffmpeg-skill` | [kajisho5/ffmpeg-skill](https://github.com/kajisho5/ffmpeg-skill) (SKILL.md + LICENSE only; the full repo with bin, references, and examples stays upstream) | MIT |
| `motion-design` | LottieFiles motion-design-skill, v1.0.0 | MIT |
| `unslop` | [Damir Sokolovsky](https://heydamir.design/unslop) | CC-BY-4.0 |

Linked only (license unclear, non-commercial, or installable upstream — never vendored):

| Skill | Install | Why linked |
| --- | --- | --- |
| `video-editing` | See [blog.moisesmelo.com](https://blog.moisesmelo.com/video-editing-with-claude) | No license recorded |
| `ai-video-prompts` | [museai-eight.vercel.app/skills/ai-video-prompts](https://museai-eight.vercel.app/skills/ai-video-prompts) | Source site, no license recorded |
| `social-media-designer` | [museai-eight.vercel.app/skills/social-media-designer](https://museai-eight.vercel.app/skills/social-media-designer) | Source site, no license recorded |
| `claude-mem` | `npx claude-mem install --setup defer` | Installs from npm (Apache-2.0) |
| `security-audit` | `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global` | Installs from upstream (MIT) |
| `modern-web-guidance` | `npx modern-web-guidance@latest install` | Installs from upstream |

The ADR skill (`architecture-decision-record`) is CC BY-NC-SA 4.0 — linked only, never vendored. It is referenced inside `repo-packaging`.

## Tools Abel made

| Tool | One line |
| --- | --- |
| `note-taker` | Private AI note taker for meetings: local Whisper + local LLM, calendar auto on/off. |
| `standup-notes` | Standup notes from git log, plus Azure DevOps work items via an input file. |
| `dependency-watch` | Weekly dependency watch: read-only, risk-grouped, baseline compare, never auto-updates. |
| `qa-agent` | Checklist QA runner with screenshots and an HTML report. |
| `codegraph-rtk-setup` | Interactive installer for CodeGraph + RTK, with a Skills step. |
| `work-laptop-local-ai` | Interactive local-AI setup for a Windows work laptop (Ollama + models). |
| `agent-worktree` | One task, one worktree, one agent: parallel Claude Code agents without shared files. |

## Tools Abel likes

| Tool | One line |
| --- | --- |
| CodeGraph | Pre-indexed code knowledge graph, 100% local. Install via `tools/made/codegraph-rtk-setup/`. |
| RTK | CLI proxy that compresses shell output 60-90% before agent context. Install via `tools/made/codegraph-rtk-setup/`. |

## Install

**Plugin (recommended).** Inside a Claude Code session:

```
/plugin marketplace add abelprasad/skills
/plugin install <plugin>@abelprasad
```

Or in one command (Claude Code 2.1.275+):

```
/plugin install <plugin> --marketplace abelprasad/skills
```

**Copy-install.** For any harness (Claude Code, Cursor, Copilot, Codex, Gemini CLI, OpenCode, local `~/.agents/skills`):

```sh
bash scripts/install.sh --all        # macOS / Linux
.\scripts\install.ps1 -All           # Windows
```

See [INSTALL.md](INSTALL.md) for the full list, per-skill picks, and what each harness path is.

## Scope

In scope, deliberately:

- Every skill Abel made, vendored verbatim, with its history intact.
- Every skill Abel likes, vendored when the license clearly permits it, linked with an install command when it doesn't.
- Every tool Abel made, self-contained, each with its own README.
- One plugin per vendored skill, so the whole collection installs as a marketplace.

Out of scope, deliberately:

- No secrets, credentials, live operational state, or money data. Ever. See [SECURITY.md](SECURITY.md).
- No live runtime directories. This repo is the public dev copy; live systems update from it, never the other way around.
- No vendoring of non-commercial or unclear-license work. Those are links, with the reason recorded in [docs/adr/0002-vendor-only-when-license-permits.md](docs/adr/0002-vendor-only-when-license-permits.md).

## Layout

```text
skills/    made/ (7) + liked/ (5 vendored, 6 linked in the catalog)
tools/     made/ (7) + liked/ (CodeGraph + RTK)
plugins/   12 Claude Code plugins, one per vendored skill
docs/adr/  5 architecture decisions
scripts/   copy-install for every harness
```

Decisions: [docs/adr/](docs/adr/). Install: [INSTALL.md](INSTALL.md). Use: [USAGE.md](USAGE.md).
