# Explorer redesign: portfolio design, collapsed by default, relevant items only

## Status

Accepted

## Context

The first explorer (ADR 0006) rendered the full 1,115-file tree with every folder open. Abel's feedback: make it more user friendly, and show only relevant stuff, collapsed by default. He also asked that the page use the same design as his portfolio site abelprasad.dev, not a generic dark editor theme.

## Decision

- Design tokens come from the portfolio source itself (`abelprasad.github.io` index.html), not guessed: paper `#fafaf7`, panel `#ffffff`, green `#16a34a`, darkGreen `#15803d`, dim `#e9f2e6`, ink `#0f2318`, muted `#456b50`, line `#d2ded0`, text `#1e2b22`. JetBrains Mono throughout. Faint green grid (7% lines, 48px cells) and the SVG paper-grain overlay (0.05 opacity) copied from the portfolio. Prompt-line section headers (`[01] abel@portfolio:~/portfolio$ cat workflow.log`) and the blinking block cursor copied from its navbar and SectionHeader.
- Two corrections from the portfolio's own unslop audit are applied here and NOT copied: headings use weight 700 (the portfolio's 800 is a slop tell) and label tracking stays at 0.1em (the portfolio's 0.2–0.35em is a slop tell). The ONLINE ping animation is not copied either — the status dot is static.
- The tree loads fully collapsed: every folder shut, only the six top-level sections visible. Expand on click. Expand all / Collapse all buttons. Expanded state persists in localStorage.
- Default view shows relevant items only: the six sections (docs, skills/made, skills/liked, tools/made, tools/liked, plugins) with one row per skill, tool, or plugin. Each row carries its name, a one-line description (from its own README / SKILL.md / plugin.json), and a labeled Download button for its primary file. Files appear only when the row is expanded. Hidden from the default view: dotfiles, `tree-snapshot.json`, `scripts/` internals, `docs/` internals, and deep vendor files.
- A "Show everything" toggle renders the full raw tree (same scope plus `scripts/`), still collapsed by default. The full raw tree is reachable but never the default.
- Search box filters rows by name and description as you type; matching sections auto-expand while searching and the count line shows the match count.
- The page stays static HTML + vanilla JS with no build step. The tree still loads live from the GitHub API with the snapshot fallback; the snapshot generator now also covers the six root docs so the fallback can render the docs section.
- Phone layout: sidebar stacks above the main pane, the tree scrolls in a capped box, rows wrap instead of overflowing.

## Consequences

- The page now looks like a page of abelprasad.dev instead of a generic dark editor. If the portfolio palette changes, the explorer tokens need a manual sync — there is no shared token file.
- Descriptions are baked into the page from each item's own docs. A new skill with no description entry still renders, just without a description line; the structure itself always comes from the live tree, so nothing can go stale structurally.
- Per-item Download fetches the item's primary file (SKILL.md / README.md / plugin.json). The whole item or whole repo still needs the folder link on GitHub or the Download-everything zip — GitHub offers no per-folder zip.
- localStorage remembers expanded folders per browser; a first-time visitor always sees the fully collapsed view.
