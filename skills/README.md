# Skills

## Made — Abel's own

Vendored verbatim from `~/workspace/custom-skills/` (and the qa-agent scaffold). These are his.

| Skill | One line | Built |
| --- | --- | --- |
| [local-ponytail](made/local-ponytail/) | Laziest working solution: YAGNI, stdlib first, one line before fifty. | — |
| [summary](made/summary/) | `/summary`: six-section handoff of everything talked and done. | Nov 16, 2026 |
| [repo-packaging](made/repo-packaging/) | ADRs, CLI product, privacy rule, dev-copy rule, presence. | Nov 15, 2026 |
| [qa-agent](made/qa-agent/) | Checklist QA with screenshots and a plain-English HTML report. | Nov 16, 2026 |
| [check_owned_before_recommending](made/check_owned_before_recommending/) | Check what Abel already owns before recommending a product. | Learned skill |
| [flagged_board_submit_handoff](made/flagged_board_submit_handoff/) | Spot a flagged job board and hand off fast with a cheat sheet. | Learned skill |
| [screenshot_guided_portal_filing](made/screenshot_guided_portal_filing/) | File in a blocking portal with screenshots instead of driving it. | Learned skill |

## Liked — vendored

The license clearly permits copying. The license file ships with the skill where upstream has one.

| Skill | Source | License | Notes |
| --- | --- | --- | --- |
| [i-have-adhd](liked/i-have-adhd/) | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | MIT | Abel's adopted version (Oct 26, 2026). Upstream MIT LICENSE included. |
| [local-ui-ux-pro-max](liked/local-ui-ux-pro-max/) | UI/UX Pro Max bundle, v2.13.0 | MIT | Trimmed working copy (4.9 MB): router SKILL.md + `cli/` sub-skills + LICENSE. The full 30 MB upstream checkout (src, stack, screenshots) is not needed to use the skill. |
| [ffmpeg-skill](liked/ffmpeg-skill/) | [kajisho5/ffmpeg-skill](https://github.com/kajisho5/ffmpeg-skill) | MIT | SKILL.md + LICENSE only. The full repo (31 MB: bin, references, examples, evals) stays upstream — see the repo link. |
| [motion-design](liked/motion-design/) | LottieFiles motion-design-skill, v1.0.0 | MIT | Full skill folder vendored. |
| [unslop](liked/unslop/) | [Damir Sokolovsky](https://heydamir.design/unslop) | CC-BY-4.0 | Full skill folder vendored with attribution. CC-BY permits sharing with credit; it is not a non-commercial license. |

## Liked — linked only, never vendored

| Skill | Install | Why linked |
| --- | --- | --- |
| video-editing | Guide: [blog.moisesmelo.com](https://blog.moisesmelo.com/video-editing-with-claude) | No license recorded for the copy Abel uses. |
| ai-video-prompts | [museai-eight.vercel.app/skills/ai-video-prompts](https://museai-eight.vercel.app/skills/ai-video-prompts) | Source site, no license recorded. The full library (545 entries) lives on the site. |
| social-media-designer | [museai-eight.vercel.app/skills/social-media-designer](https://museai-eight.vercel.app/skills/social-media-designer) | Source site, no license recorded. |
| claude-mem | `npx claude-mem install --setup defer` | Installs from npm. [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) (Apache-2.0). |
| security-audit | `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global` | Installs from upstream. [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) (MIT). |
| modern-web-guidance | `npx modern-web-guidance@latest install` | Installs from upstream (Google Modern Web Guidance 1.0). |

The ADR skill ([architecture-decision-record/architecture-decision-record](https://github.com/architecture-decision-record/architecture-decision-record)) is CC BY-NC-SA 4.0 (non-commercial) — linked only, never vendored. It is referenced inside `repo-packaging`.

Rule: if a license is unclear or non-commercial, link it, don't copy it. See `docs/adr/0002-vendor-only-when-license-permits.md`.
