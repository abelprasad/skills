# Use one central repo

## Status

Accepted

## Context

Nov 16, 2026. Abel asked why the scaffolds and setup packs weren't on GitHub, then asked for somewhere to store all the skills he likes and makes and all the tools and plugins he likes and makes. The first plan was 6 separate public repos (one per scaffold/pack) plus a 7th central store. Abel corrected that in one line: "no not those separate 6". He wants one place, not six.

## Decision

One public repo, `abelprasad/skills`, holds everything: skills he made, skills he likes, tools he made, tools he likes, and the plugin marketplace. The 6 scaffolds/packs live here as folders under `tools/made/`. No separate repos for them.

## Consequences

- One link, one presence, one place to maintain. One clone gets everything; updates are one push.
- Issues and pull requests mix across tools in one tracker. Acceptable: Abel is the only maintainer.
- Cloning pulls everything (about 23 MB at v0.1.0), including tools a user may not want. Acceptable for a personal collection; the copy-install scripts let users pick individual skills.
- The local `~/workspace/` copies stay the canonical dev copies; this repo is the public copy.
