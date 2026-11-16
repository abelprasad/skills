---
name: summary
description: Summarize everything talked and done in a session or thread into a clean handoff summary, with decisions, state, files, and next steps. Use at the end of a session, before compaction, when handing work to another agent, or when Abel asks for a summary of everything so far.
---

# Summary

Turn a long conversation into a clean handoff summary. The summary is what
the next session (or another agent) needs to pick up the work without
re-reading the whole thread.

## When to use

- Abel says "summarize", "give me a summary", "what did we do", or asks
  for a recap at the end of a session.
- Before compaction, or when the thread is getting long and the context
  window is at risk.
- Handing work to another agent, or resuming work after a break.
- `/summary <topic>` narrows to one thread (e.g. `/summary dogsrun`).
  `/summary --save <path>` also writes the summary to a file.

## What to read first

Read in this order, before writing anything:

1. `~/MEMORY.md` — the curated standing facts. If the transcript
   contradicts MEMORY.md, the latest evidence wins, and the summary says
   so.
2. `~/memory/<today>.md` and recent daily notes — the running log of what
   happened, with dates.
3. Goal files under `~/workspace/goals/<goal-slug>/` for any goal the
   session touched.
4. The transcript itself, oldest to newest. A summary that only reads
   MEMORY.md is a memory dump, not a session summary.

Reconcile conflicts by latest evidence: a user correction beats an
earlier assistant claim, and a verified tool result beats both.

## What a good summary contains

Six sections, in this order. Keep each section tight; cap lists at 5
items per section unless completeness matters (e.g. a full list of
submissions with IDs must stay complete).

### 1. Decisions made

- The decision, the date it was made, and who made it (Abel, or the
  agent with Abel's go).
- Quote Abel's corrections verbatim where they change a standing rule
  (e.g. "u don't have to ask me for approval to post").
- Never present a proposal as a decision. A widget with no tap is
  "offered, no reply", not "approved".

### 2. Work done

- What was built, changed, installed, submitted, or verified.
- Verification numbers, not adjectives: tests passed, file counts,
  versions, exit codes, timestamps.
- State the outcome plainly: done, verified, failed, or partial. A
  failed run is still a result; report what actually happened.

### 3. Files created or changed

- Full paths. When the summary is shown to Abel, file paths are
  sandbox links so he can open them.
- For each file: one line on what it is and why it exists.
- Repos: branch, HEAD commit, what is pushed vs unpushed. Never claim
  something is pushed when it is not.

### 4. State per thread

One line per thread, with one of these states:

- **Done** — verified, nothing left.
- **In progress** — who is doing it, where it stands, what is next.
- **Blocked** — what blocks it, and what would unblock it.
- **Awaiting user** — the exact question or tap needed, and what happens
  on each answer.

### 5. Open questions and next steps

- In priority order. The top item is the single next action.
- Each item names who acts (Abel, or the agent) and what the trigger is.

### 6. Standing rules touched

- Any rule created, strengthened, or corrected in this session, with the
  date and the exact wording Abel used.
- Do not re-state rules the session never touched.

## What it must NOT do

- Never invent an ID, date, number, or outcome. If it is not in the
  transcript, a file, or a tool result, say "unknown" and say what would
  settle it.
- Never mark unsubmitted as submitted, unmerged as merged, or unpushed
  as pushed. Submitted / merged / pushed need a confirmation, a link, or
  a commit hash.
- Never drop an open decision to make the summary shorter. An unanswered
  question stays in section 5.
- Never re-litigate a conceded point. If Abel corrected the agent, the
  correction stands and the summary records it.
- Never include a secret, password, token, cookie, OTP, or credential
  value. A credential existing is a fact; its value is never in a
  summary.
- Never include company data Abel refused to share. If the session
  touched Ascensus work, record only the generic scaffold, never repo
  names, commands, checklists, or code.

## Output format

- No preamble, no filler closers. First line is the most important
  outcome or the next action.
- Short sections with headers, one idea per line. Lists capped at 5 per
  section unless completeness matters.
- Timestamps in America/New_York (ET), with the date. Use the time tags
  in the transcript, not guesses.
- File paths as sandbox links when shown to Abel
  (e.g. `[README.md](sandbox://workspace/<path>/README.md)`).
- End with one concrete next action, doable in under 2 minutes.

## How to handle a huge thread

- If the transcript is too long to hold at once, summarize it in chunks
  (oldest first), then merge the chunk summaries, keeping only decisions,
  state changes, and open items.
- If a daily note already covers a day, quote it and do not re-derive it
  from the transcript.
- If two sources disagree, keep both, label which is newer, and say what
  check would settle it. Never silently pick one.

## Example skeleton

```markdown
# Summary — <date>

## Decisions
- ...

## Work done
- ...

## Files
- ...

## State
- <thread>: <done | in progress | blocked | awaiting user> — ...

## Next steps
1. ...

## Rules touched
- ...
```
