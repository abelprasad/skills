# Plugins

One Claude Code plugin per vendored skill, installable as a marketplace.

## Install

Inside a Claude Code session:

```
/plugin marketplace add abelprasad/skills
/plugin install <plugin>@abelprasad
```

Or in one command (Claude Code 2.1.275+):

```
/plugin install <plugin> --marketplace abelprasad/skills
```

The marketplace manifest is `.claude-plugin/marketplace.json` at the repo root.

## Plugins

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

## Layout

Each plugin is `plugins/<name>/` with `.claude-plugin/plugin.json`, a README, and `skills/<name>/` holding the skill files. `summary` and `qa-agent` also ship slash commands under `commands/`.

Note: the `skills/<name>/` copy inside each plugin duplicates the catalog copy under `skills/made/` or `skills/liked/`. The catalog copy is canonical; the plugin copy is the install copy. See `docs/adr/0005-plugin-skills-duplicate-catalog-copies.md`.

Validate before committing: `claude plugin validate .claude-plugin/marketplace.json` and `claude plugin validate plugins/<name>`.
