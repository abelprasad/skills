# Contributing

This is Abel's personal collection. Outside contributions are welcome if they follow the rules below.

## Adding a skill

1. Check its license first. MIT / Apache-2.0 / CC-BY: vendor it, with the license file and an attribution line in `skills/README.md`. Anything non-commercial or unclear: link it in `skills/README.md` with an install command, never copy it. See `docs/adr/0002-vendor-only-when-license-permits.md`.
2. Made skills go in `skills/made/`. Liked skills go in `skills/liked/`.
3. Add a plugin for it in `plugins/<name>/` (plugin.json + README + `skills/<name>/` copy). Run `claude plugin validate` on the marketplace before committing.
4. Add a row to the catalog in `skills/README.md` and the root README.

## Adding a tool

1. It goes in `tools/made/` with its own README, placeholders only, no secrets, no live state.
2. Add a row to `tools/README.md` and the root README.
3. If it changes a decision recorded in `docs/adr/`, write a NEW ADR that supersedes the old one. Never rewrite an existing ADR.

## Commits

Atomic, dev-readable: one change per commit, imperative subject (`docs: add ADRs`, `feat: add note-taker tool`). Run a secret scan before pushing.
