# summary skill

Turn a long conversation into a clean handoff summary.

## What it is

- **Skill:** `custom-skills/summary/SKILL.md` — what a good summary
  contains, what it must never do, and the output format.
- **Command:** `custom-skills/summary/commands/summary.md` — the
  `/summary` slash command doc.

## How to use it

In Muse (this chat): type `/summary`, or `/summary <topic>`, or add
`--save <path>` to also write it to a file.

In Claude Code (on indra): the skill is installed at
`~/.claude/skills/summary/SKILL.md` and the command at
`~/.claude/commands/summary.md`. Same usage: `/summary`,
`/summary <topic>`, `/summary --save <path>`.

## Example output skeleton

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

See [EXAMPLE.md](sandbox://workspace/custom-skills/summary/EXAMPLE.md)
for a worked example: the summary of building this skill itself.
