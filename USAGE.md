# Usage

## Skills

Each skill has its own SKILL.md — read it before using it. The one-line version:

- `local-ponytail`: say "ponytail", "lazy mode", or "simplest solution" on any coding task. Levels: lite, full (default), ultra. "stop ponytail" turns it off.
- `summary`: `/summary` at the end of a session. `/summary <topic>` narrows it. `/summary --save <path>` writes it to a file.
- `repo-packaging`: say "package it" before pushing a repo public. ADRs first, then CLI product, then skill bundle, then push.
- `qa-agent`: `/qa-test <site-url> <checklist.yaml>` — or run `run-qa.bat` from `tools/made/qa-agent/`.
- `i-have-adhd`: always on until Abel says "stop adhd mode". Action first, numbered steps, one concrete next action, lists capped at 5.
- `check_owned_before_recommending`, `flagged_board_submit_handoff`, `screenshot_guided_portal_filing`: trigger skills — they fire when the situation matches, no command needed.
- `local-ui-ux-pro-max`: read `cli/assets/skills/design/SKILL.md` first when a task spans more than one design area.
- `ffmpeg-skill`, `motion-design`, `unslop`: use when the task names them — video work, motion work, or a screen that looks AI-generated.

## Tools

- **note-taker**: runs on the work laptop. `run-notes.bat` watches the calendar (Outlook COM live, `.ics` fallback), records system audio + mic, transcribes locally with Whisper, summarizes only decisions and action items with a local model, writes `notes/YYYY-MM-DD_HHMM_<title>.md`, deletes the audio. Details in `tools/made/note-taker/README.md`.
- **standup-notes**: `standup.bat` (or `standup.sh`) writes today's standup from git log since yesterday 09:00. With `standup-items.json` from the Azure DevOps MCP dump step, work items merge in: Done to Yesterday, open to Today, blocked to Blockers. Details in `tools/made/standup-notes/README.md`.
- **dependency-watch**: `run-watch.bat` checks npm, NuGet, and pip (read-only), groups by risk, compares against `out/baseline.json`, and says "no changes since last run" when nothing moved. Never auto-updates. `register-watch.bat` schedules it weekly, Monday 08:00. `STOP` file or `unregister-watch.bat` kills it. Details in `tools/made/dependency-watch/README.md`.
- **qa-agent**: `run-qa.bat <site-url> <checklist.yaml>` runs the checklist against the site, screenshots every step, writes a plain-English HTML report. Details in `tools/made/qa-agent/README.md`.
- **codegraph-rtk-setup / work-laptop-local-ai**: interactive installers. Run once, pick from the menu, done. Details in their READMEs.
- **agent-worktree**: `agent-worktree.sh add <repo> <task>` makes a detached worktree per agent. Read `tools/made/agent-worktree/WORKTREES.md` first.

## What not to do

- Don't paste company data, credentials, or live state into any of these tools' configs in a shared place. Configs here are placeholders; real values live on the machine that runs them.
- Don't run the QA agent's example checklist against a real site and expect real results — it targets a demo site.
- Don't vendor a new skill into `skills/liked/` without checking its license first. See ADR 0002.
