# Static Pages explorer page

## Status

Accepted

## Context

The repo is the storefront, but a GitHub file listing is a poor way to browse a collection of skills and tools. Abel asked for a "copy my workflow" page: a mini VS Code window with a file explorer, per-file download, a download-everything button, and the one-command installer front and center. It has to stay in sync with the repo without anyone maintaining a list by hand.

## Decision

- One static page, `docs/index.html`, served by GitHub Pages from the repo's `docs/` folder. HTML + vanilla JS, no build step, no backend.
- The tree is generated from the live tree, never a hand-maintained list: the page reads `https://api.github.com/repos/abelprasad/skills/git/trees/main?recursive=1` (public repo, no token) and renders `skills/made`, `skills/liked`, `tools/made`, `tools/liked`, `plugins`.
- If the API fails, the page falls back to `docs/tree-snapshot.json`, generated at build time by `scripts/generate-pages-snapshot.py`, and says so on the page with the snapshot timestamp.
- Per-file download uses raw.githubusercontent.com links. "Download everything" uses the codeload zip. The installer commands shown are the repo's real commands (`scripts/install.sh --all` and the two setup-pack installers).
- The featured repos section is a hand-picked short list (the repo's own catalog plus flagship repos), never an auto-list of all of Abel's repos. Only repos that exist on GitHub get a link; anything not pushed yet is marked coming soon with no link.

## Consequences

- The page cannot drift from the repo: the tree comes from the API on every load. The snapshot only covers API outages, and regenerating it is one script run.
- The page is a second consumer of the repo layout. Renaming a top-level folder means updating the ROOTS list in the page.
- GitHub Pages builds from `main` on push; the page can lag the push by a few minutes. The snapshot timestamp shows its age.
