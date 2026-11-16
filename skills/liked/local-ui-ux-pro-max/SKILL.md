---
name: local-ui-ux-pro-max
description: 'Design intelligence bundle: brand identity, design tokens, UI styling with shadcn/ui and Tailwind, logos, banners, slides, and icons. Route each design task to the matching sub-skill.'
---

# UI/UX design skills

## Pick the right sub-skill

- This folder holds the vendored UI/UX Pro Max bundle (MIT, v2.13.0). Route each design task to the matching sub-skill below and read its SKILL.md before starting work. Each sub-skill carries its own references, scripts, and templates.

- Read `cli/assets/skills/design/SKILL.md` first when the task spans more than one design area. It routes brand identity, logos, corporate identity deliverables, mockups, icons, social photos, and HTML presentations.

- Read `cli/assets/skills/ui-styling/SKILL.md` for interface building. It covers shadcn/ui components on Radix plus Tailwind utility styling, responsive layouts, dark mode, and accessible dialogs, forms, tables, and data-dense patterns.

- Read `cli/assets/skills/design-system/SKILL.md` when the work needs a system instead of a screen. It defines the three-layer token architecture (primitive, semantic, component), CSS variables, spacing and typography scales, component specs, and Tailwind theme configuration.

- Read `cli/assets/skills/brand/SKILL.md` for identity work. It covers brand voice, messaging frameworks, visual standards, asset validation, and brand consistency audits. Run it before generating assets that must stay on-brand.

- Read `cli/assets/skills/banner-design/SKILL.md` for banners only. It designs social covers, ad creatives, website heroes, and print banners across 13 art directions with bundled size and safe-zone guidance. It does not handle video or full sites.

- Read `cli/assets/skills/slides/SKILL.md` for decks. It builds strategic HTML presentations with Chart.js charts, design tokens, and copywriting formulas for pitch decks and data-driven presentations.

## Run scripts from the project root

- Resolve script paths relative to the sub-skill's own folder, not the project. Keep the working directory at the project root, since the scripts read and write project files such as `docs/brand-guidelines.md` or `assets/design-tokens.json` relative to it.

- Run the sub-skill's validation scripts where they exist, such as brand asset validation, before calling a design done. Check visual output in the browser when the result is meant to be seen.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Skip the bundle for small polish jobs and go straight to `ui-styling`. The full router earns its keep on multi-area work.

- Compare against Impeccable (pbakaus/impeccable) for a second opinion on design rules. It is flagged for future per-project evaluation but not installed. Evaluate it only on request, and report how it compares before adopting it anywhere.
