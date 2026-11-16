# Bundled skills

These skill folders are what the Skills step installs. They ship inside the
pack so install works offline, and they are the exact versions Abel already
uses — not a fresh download that could differ.

| Skill | One line | Source |
| --- | --- | --- |
| i-have-adhd | ADHD output protocol: action first, numbered steps, no preamble | ayghri/i-have-adhd (MIT), https://github.com/ayghri/i-have-adhd — Abel's adopted version (Oct 26, 2026). Upstream SKILL.md lives at skills/i-have-adhd/SKILL.md in that repo. |
| local-ponytail | Laziest working solution: YAGNI, stdlib first, one line before fifty | Abel's own skill |
| summary | /summary: six-section handoff of everything talked and done | Abel's own skill, built Nov 16, 2026 |
| repo-packaging | ADRs, CLI product, privacy rule, dev-copy rule, presence | Abel's own skill, built Nov 15, 2026 |
| qa-agent | Checklist QA with screenshots + HTML report | Abel's own skill, built Nov 16, 2026 |
| local-ui-ux-pro-max | Design bundle: shadcn + Tailwind, brand, banners, slides | Vendored UI/UX Pro Max bundle (MIT, v2.13.0). The router SKILL.md points at the `cli/` sub-skills, which are included in this folder — do not install SKILL.md alone. |

Notes:
- The bundled i-have-adhd, local-ponytail, repo-packaging, and
  local-ui-ux-pro-max copies have a small YAML frontmatter block (name +
  description) added at the top so harnesses can discover them. The body
  text is verbatim Abel's adopted version. summary and qa-agent already
  carry frontmatter; their files are verbatim.
- local-ponytail also ships its skill.yaml; local-ui-ux-pro-max also ships
  its cli/ subtree and LICENSE; i-have-adhd also ships the upstream MIT
  LICENSE. The installer copies the whole skill folder, not just SKILL.md.
- If a skill folder is missing when the installer runs, it is simply not
  offered. For i-have-adhd only, the installer falls back to downloading
  the upstream SKILL.md from
  https://raw.githubusercontent.com/ayghri/i-have-adhd/main/skills/i-have-adhd/SKILL.md
  (the upstream text, not Abel's adopted version — the installer says so).

## Optional external installs (not bundled, opt-in only)

These are not in this folder. The installer offers them separately, never
in "All", and each asks for confirmation before running. Both need Node.js.

| Install | Command (verified from its README Nov 16, 2026) |
| --- | --- |
| claude-mem | `npx claude-mem install --setup defer` — persistent memory across sessions. Setup deferred to first session; observer trial asks for a payment method; memory lives in `~/.claude-mem`. https://github.com/thedotmack/claude-mem (Apache-2.0) |
| security-audit | `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global` — multi-phase security audit skill. https://github.com/cloudflare/security-audit-skill (MIT) |
