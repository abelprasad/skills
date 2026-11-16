# Keep tools self-contained

## Status

Accepted

## Context

The 6 scaffolds/packs were built as standalone folders, each with its own README and installer: the note taker, standup notes, dependency watch, QA agent, CodeGraph+RTK setup pack, and work-laptop-local-AI pack. The two setup packs each bundle their own `skills/` copy (6 skills, 4.9 MB, mostly the UI/UX bundle) so their installers work offline. Moving them into one repo tempted a deduplication: one shared `skills/` folder for all of them.

## Decision

Keep each tool self-contained exactly as built. The setup packs keep their bundled `skills/` copies. The note taker, standup notes, dependency watch, and QA agent keep their own READMEs, configs, and runners. No tool imports from another tool's folder.

## Consequences

- The repo carries duplicate copies of the same skill bundle (one per setup pack, plus the catalog copy, plus the plugin copy). About 23 MB total at v0.1.0. Accepted: each tool works if copied out of the repo on its own, which is the point of a tool.
- A skill fix has to be applied in each place it is bundled. The catalog copy under `skills/` is canonical; the others are install copies.
- The privacy rule still applies per tool: no secrets, no live state, no company data in any folder. Verified with a secret scan before every commit.
