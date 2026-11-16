# Publish skills as a Claude plugin marketplace

## Status

Accepted

## Context

Abel wants a presence and one place to install from. The clipsdaily repo (Nov 15, 2026) already proved the pattern: a `.claude-plugin/marketplace.json` at the repo root plus one plugin dir per skill, validated with `claude plugin validate`. The alternative was copy-install only, which works everywhere but is a manual step per skill per harness.

## Decision

Ship both, plugin first:

- Marketplace manifest `.claude-plugin/marketplace.json` at the repo root, marketplace name `abelprasad`, one plugin per vendored skill (12 at v0.1.0).
- Each plugin is `plugins/<name>/` with `.claude-plugin/plugin.json`, a README, and `skills/<name>/`. Slash commands ride along where they exist (`/summary`, `/qa-test`).
- Copy-install scripts (`scripts/install.sh`, `scripts/install.ps1`) stay as the fallback for non-Claude harnesses: Claude Code, Cursor, Copilot, Codex, Gemini CLI, OpenCode, local `~/.agents/skills`.
- Validate with `claude plugin validate` on the marketplace manifest and on each plugin dir before committing.

## Consequences

- Install is one command per plugin, or one marketplace add for all of them.
- The marketplace format is Claude Code-specific. Other harnesses use the copy-install scripts; slash commands stay Claude-Code-only by design.
- Plugin copies duplicate the catalog copies (see ADR 0005). That duplication is the cost of the marketplace format.
