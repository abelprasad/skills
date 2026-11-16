---
description: Summarize everything talked and done in the current session (or one topic) into a clean handoff summary with decisions, state, files, and next steps.
---

# /summary

Summarize everything talked and done in this session, or one topic only.

## Usage

```
/summary
/summary <topic>
/summary --save <path>
/summary <topic> --save <path>
```

- No arguments — summarize the whole current session.
- `<topic>` — one thread only (e.g. `/summary dogsrun`,
  `/summary clipsdaily`, `/summary local-ai`). Everything outside that
  topic is left out.
- `--save <path>` — also write the summary to that file. Default when
  omitted: show it in chat only. Example:
  `/summary --save ~/workspace/summary-2026-11-16.md`.

## What it runs

There is no runner script. The agent reads, in order:

1. `~/MEMORY.md` and `~/memory/<today>.md` plus recent daily notes.
2. Goal files under `~/workspace/goals/<goal-slug>/` for any goal the
   session touched.
3. The transcript, oldest to newest.

Then it writes the summary in the skill's format: Decisions, Work done,
Files, State per thread, Next steps, Rules touched.

## What it reads

- The current session transcript.
- MEMORY.md, daily notes, and goal files (see above).
- Files the session created or changed, to confirm paths, sizes, and
  states (pushed vs unpushed, submitted vs unsubmitted).

## What it outputs

- A summary in chat, in the skill's six-section format.
- With `--save`, the same summary as a Markdown file at `<path>`.

## What it never does

- Never invents an ID, date, number, or outcome. Unknown stays unknown,
  with what would settle it.
- Never marks unsubmitted as submitted, unmerged as merged, or unpushed
  as pushed.
- Never drops an open decision to make the summary shorter.
- Never includes a secret, password, token, cookie, OTP, or credential
  value.
- Never includes company data Abel refused to share (no repo names,
  commands, checklists, or code).

## Example

```
/summary dogsrun --save ~/workspace/summary-dogsrun-2026-11-16.md
```

Then open the saved file, or read the summary in chat.
