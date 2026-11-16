# Vendor only when the license permits

## Status

Accepted

## Context

This repo collects other people's skills. Copying a skill into the repo is redistribution, and the licenses differ: MIT and Apache-2.0 permit it, CC-BY-4.0 permits it with attribution, CC BY-NC-SA 4.0 forbids commercial use, and some skills ship with no license recorded at all. This repo is public and Abel's work is revenue-seeking, so a non-commercial license is a real conflict, not a technicality.

## Decision

- MIT / Apache-2.0 / CC-BY: vendor the files, ship the license file where upstream has one, and name the source in `skills/README.md`. CC-BY keeps its attribution.
- Non-commercial (e.g. CC BY-NC-SA) or unclear/no license: link only, with an install command and the reason recorded. Never copy the files.
- Where vendoring the whole upstream repo is impractical (ffmpeg-skill is 31 MB), vendor the SKILL.md + LICENSE and link upstream for the rest, saying so in the catalog.
- Where a bundled copy is trimmed for size (local-ui-ux-pro-max: the 4.9 MB working copy, not the 30 MB upstream checkout), record the trim in the catalog.

## Consequences

- `skills/liked/` is split by design: vendored folders plus a link-only table. A reader can tell at a glance what is copied and what is referenced.
- Link-only skills can rot if upstream moves. The install commands are verified from the upstream README at the time of linking; re-verify when touching them.
- The ADR skill itself (architecture-decision-record, CC BY-NC-SA) is link-only. The repo-packaging skill references it; it is never vendored.
