# Summary — Nov 16, 2026 (01:04–01:06 EST)

Worked example for the /summary skill: the summary of building the
/summary skill itself.

## Decisions

- Abel asked Nov 16, 2026 ~01:04 EST: "give me a summary of everything
  we talked and did at the end turn that into a /summary skill as well".
- Skill built in both places: local `~/workspace/custom-skills/summary/`
  and indra `/home/abel/.claude/skills/summary/` plus the command at
  `/home/abel/.claude/commands/summary.md`.
- Indra commands location: no `/home/abel/.claude/commands/` directory
  existed before this task. The standard Claude Code user-command
  location `~/.claude/commands/` was created for it, and recorded here.

## Work done

- Read the reference pattern: `repo-packaging/SKILL.md`,
  `i-have-adhd/SKILL.md`, `qa-agent/SKILL.md` + `commands/qa-test.md`.
- Wrote the skill (5,523 bytes), the slash command doc (2,096 bytes),
  and a README (1,040 bytes).
- Installed on indra as abel via SSH (proxy restored from
  `~/workspace/ssh-tail-proxy.py`). First skill copy failed because the
  `skills/summary/` directory did not exist; fixed with `mkdir -p` and
  re-ran. No live service, tmux session, or repo touched.
- Verified: md5 identical local vs indra for both files
  (SKILL.md `7e99add61258651557f6ee5ac6dd03b9`, summary.md
  `396b50b2f44d6c3ab41801240e11fe27`); `ls` shows `summary` in
  `/home/abel/.claude/skills/`.

## Files

- [SKILL.md](sandbox://workspace/custom-skills/summary/SKILL.md) —
  the skill: when to use, what to read first, six sections, never-dos,
  output format.
- [commands/summary.md](sandbox://workspace/custom-skills/summary/commands/summary.md) —
  the /summary command: `/summary`, `/summary <topic>`,
  `/summary --save <path>`.
- [README.md](sandbox://workspace/custom-skills/summary/README.md) —
  10-line guide for Muse and Claude Code.
- [EXAMPLE.md](sandbox://workspace/custom-skills/summary/EXAMPLE.md) —
  this file.
- Indra: `/home/abel/.claude/skills/summary/SKILL.md` and
  `/home/abel/.claude/commands/summary.md` (new `commands/` directory).

## State

- summary skill: done, verified on both sides.
- /summary command: done, installed, not yet run inside a live
  Claude Code session.

## Next steps

1. Run `/summary` once at the end of a real session to prove the
   format in live use.

## Rules touched

- None. No standing rule was created, changed, or corrected in this task.
