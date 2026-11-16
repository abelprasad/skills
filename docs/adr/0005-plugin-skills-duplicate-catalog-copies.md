# Plugin skills duplicate catalog copies

## Status

Accepted

## Context

The Claude plugin format puts a plugin's skills inside the plugin directory (`plugins/<name>/skills/<name>/`). This repo also keeps one canonical copy of every skill under `skills/made/` or `skills/liked/` so the collection is browsable without the plugin machinery. A plugin cannot reference a skill outside its own directory, so one of the two copies has to be a duplicate. Symlinks were considered and rejected: they break on Windows checkouts without Developer Mode, and this repo targets Windows work laptops.

## Decision

Duplicate the small files. Each plugin ships its own copy of its skill under `plugins/<name>/skills/<name>/`. The catalog copy under `skills/` is canonical. The two big skills (local-ui-ux-pro-max, unslop) are duplicated too — disk is cheap, broken installs are not.

## Consequences

- A skill edit must land in both places (catalog + plugin). The plugin README in each plugin dir says where the canonical copy lives.
- Repo size grows with each vendored skill (about 23 MB at v0.1.0, mostly the UI/UX bundle in three places). Accepted.
- If the plugin format ever supports referencing skills outside the plugin dir, this ADR gets superseded and the duplicates get deleted.
