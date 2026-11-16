# repo-packaging

Turn any repo from flat scripts into a real CLI product, the way the
clipsdaily repo was packaged on Nov 15, 2026. The playbook was built from
three reference repos Abel pointed at that night:

- architecture-decision-record/architecture-decision-record — ADRs
- alibaba/open-code-review — CLI product
- elementalsouls/Claude-BugHunter — skill-bundle-first

Apply it to every repo. Live and active repos first, then the rest.

## When to use

- Abel says "package it", "package it like this", or asks to make a repo
  public-ready, presentable, or installable.
- Before pushing any repo public.
- When a repo is flat scripts and should be a product instead.

## The checklist

Work the six items in order. Audit first, package second. Never
restructure or commit without Abel's go.

### 1. ADRs (architecture-decision-record)

- One `.md` file per decision in `docs/adr/`.
- Nygard template, exactly these sections: Title, Status, Context,
  Decision, Consequences.
- Filename: present-tense imperative verb phrase, lowercase + dashes,
  `.md` (e.g. `use-full-frame-vertical-video.md`).
- ADRs are immutable. Never rewrite an existing ADR. A changed decision
  gets a NEW ADR that supersedes the old one, and the old one's Status
  becomes Superseded with a pointer to the new one.
- Index in `docs/adr/README.md` (the ADL: number, title, status, date),
  linked from the main README.
- Record real decisions with real dates, including what failed before the
  decision. One decision per ADR, no more.

### 2. CLI product (open-code-review)

- A real installable CLI, not flat scripts run as `python3 xxx.py`.
- `pyproject.toml` + `src` layout + a console script entry point
  (e.g. `clipsdaily` with subcommands: run, post, queue, campaign,
  submit, earnings, status).
- The CLI is a thin entry layer over the existing modules. Do not rewrite
  the pipeline logic to package it.
- One-command install: `pipx install git+https://github.com/abelprasad/<repo>`
  (once pushed) or `bash install.sh --local` from a clone.
- Agent plugin with slash commands + skills. Claude Code layout:
  `.claude-plugin/plugin.json` + `commands/` + `skills/<name>/SKILL.md`.
  Validate with `claude plugin validate` before committing.
- Docs organized as quickstart / installation / CLI reference / config /
  operations / FAQ. CLI reference is generated from the real CLI, never
  hand-written.
- CONTRIBUTING.md, LICENSE (MIT), ROADMAP.md, GOVERNANCE.md.
- Makefile with install, test, lint, check, docs, deploy, clean.
- GitHub Actions CI: compile all code, run the smoke test
  (`<cli> --help` plus every subcommand `--help`), secret scan.
- Versioned releases: a `VERSION` file (`0.1.0`), `vX.Y.Z` tags, no
  release until the push decision is made.

### 3. Skill-bundle-first (Claude-BugHunter)

- Plugin install (recommended):
  `/plugin marketplace add abelprasad/<repo>` +
  `/plugin install <plugin>@abelprasad`.
- Copy-install for non-plugin users: `scripts/install.sh` (macOS/Linux)
  and `scripts/install.ps1` (Windows), copying skills + commands into
  `~/.claude/`.
- `--all` multi-harness support in the install scripts: detect installed
  harnesses and copy the skill to each path — OpenCode/Codex
  `~/.agents/skills`, Hermes `~/.hermes/skills`, Gemini
  `~/.gemini/config/skills`. Slash commands stay Claude-Code-only by
  design; note that.
- Docs split: `INSTALL.md`, `USAGE.md`, `CHANGELOG.md`, `SECURITY.md`
  (licensing, what the tool may and may not do, what content it may use).
- README leads with the numbers (counts of modules, commands,
  platforms, cadence, ADRs).
- README has an explicit Scope section: In scope / Out of scope, framed
  as deliberate design decisions, not gaps.
- Star History chart (self-hosted generator + daily workflow, or the
  star-history.com snippet).
- Author byline: `Built by [Abel Prasad](https://www.linkedin.com/in/abel-prasad)`
  + [abelprasad.dev](https://abelprasad.dev) (primary portfolio;
  abelprasad.github.io also exists). Never invent a link.

### 4. Privacy rule — recipe vs food in the fridge

- Anything that is a secret, a credential, live operational state, or
  money data stays private and out of git (`.gitignore`).
- Code, docs, and config templates can be public.
- The repo ships the code that builds the state, never the state itself.
- Live state includes: `queue/`, `.auth/`, `clips/`, `vod/`,
  `recordings/`, `logs/`, `earnings.json`, `campaigns.json`,
  `submit-outbox/`, and all media. Sanitize example configs too —
  scrub real IDs even when they appear as dict keys, not just values.
- Verify with a secret scan before every commit. A hit on a file path
  (e.g. `.auth/youtube_token.json` named in a doc) is fine; a value is
  never fine.

### 5. Dev-copy rule

- The repo is the canonical dev copy where work happens.
- The live/runtime directory is separate. It is only updated via
  `deploy.sh`, which backs up, installs, and restarts services.
- Never edit the live dir by hand. Never run a live deploy without
  Abel's go. A dry-run of `deploy.sh` is the verification step.
- Never run `restart_maintainer.py` or any one-off reset script that
  wipes live state — it is stale.

### 6. Presence

- A public repo is the storefront. README + diagrams are the first thing
  people see; keep them current.
- Mermaid diagrams in the README (pipeline, cadence, lifecycle,
  repo-vs-runtime) beat paragraphs for architecture.

## Audit procedure

Before packaging any repo, audit it read-only against the checklist.
Do not clone full repos; use the GitHub API + targeted raw reads.

1. List repos: `gh api users/abelprasad/repos --paginate` (unauthenticated
   is fine; 24 public repos as of Nov 9, 2026).
2. Per repo, one call: `gh api
   repos/abelprasad/<repo>/git/trees/<default-branch>?recursive=1`.
   The tree gives every path; from it check:
   - `docs/adr/` present?
   - `LICENSE` present?
   - `pyproject.toml` / `package.json` / `install.sh` present, or flat
     scripts only?
   - `.github/workflows/` present?
3. Fetch `README.md` raw (one fetch per repo) and check for the author
   byline (LinkedIn / abelprasad.dev).
4. Produce a compact table: repo, which of the six items it has/misses.
5. Recommend an order (live/active repos first). Do not apply it.

## Rules

- Audit first, package second, push last. Push public vs private is
  Abel's call every time; never decide it for him.
- Never include a credential, token, cookie, or secret in any file.
- Never touch a live runtime dir or any repo's working tree without a
  go.
- Never run a live deploy without Abel's go.
- If a reference repo's license is unclear or non-commercial (e.g. CC
  BY-NC-SA), link to its skill instead of vendoring it, and record why.
- Verify in a fresh venv: install works, `<cli> --help` lists
  subcommands, every `.py` compiles, the e2e test passes, git status
  is clean after the commit.
