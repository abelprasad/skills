# Parallel agents in worktrees

One task, one worktree, one agent. Agents never share files, so they can
run at the same time without stepping on each other.

## The pattern

1. `agent-worktree.sh add <repo> <task>` — detached worktree at
   `/home/abel/worktrees/<repo>-<task>/`, at the repo's HEAD.
2. Start Claude Code in it, in tmux (below). The agent works only there.
3. When it finishes, review the diff, merge the tip commit into the main
   checkout, then delete the worktree.

## Rules

- Never two agents on the same files. One worktree per agent, always.
- Never edit the main checkout while an agent owns a worktree of that repo.
- Merge back only after reading the diff.
- Delete the worktree after merging. Stale worktrees rot.
- Long jobs run detached in tmux; never inject into a live Claude session.
- Run everything as abel, never as root, or files end up root-owned.
  (Friday runs these via `sudo -n -u abel`.)

## Commands

```sh
# create (ref defaults to HEAD; pass a branch or sha to pin it)
~/agent-worktree.sh add /home/abel/dogsrun pspca-adapter

# start the agent, interactive in tmux
tmux new-session -d -s wt-dogsrun-pspca-adapter \
  "cd /home/abel/worktrees/dogsrun-pspca-adapter && /home/abel/.npm-global/bin/claude"
tmux attach -t wt-dogsrun-pspca-adapter

# one-shot instead (no tmux)
cd /home/abel/worktrees/dogsrun-pspca-adapter && \
  /home/abel/.npm-global/bin/claude -p "<task>"

# status
~/agent-worktree.sh list
tmux ls

# merge back (from the main checkout; sha = worktree tip)
git -C /home/abel/worktrees/dogsrun-pspca-adapter log --oneline -3
git -C /home/abel/dogsrun merge <sha>

# clean up (refuses with uncommitted changes unless --force)
~/agent-worktree.sh rm dogsrun-pspca-adapter
```

## Where it maps

- DOGSRUN: `/home/abel/dogsrun` — e.g. `add /home/abel/dogsrun pspca`
  (the existing `/home/abel/dogsrun-pspca` worktree was made by hand; new
  ones go under `/home/abel/worktrees/`).
- bell-broom-web: `/home/abel/bell-broom-web` — e.g. `add ... booking-flow`
- clipsdaily-repo: `/home/abel/clipsdaily-repo` — the dev copy; e.g.
  `add /home/abel/clipsdaily-repo tiktok-fix`

## Notes

- Worktrees share the repo's `.git`, so commits in a worktree are visible
  from the main checkout immediately. A branch can only be checked out in
  one place at a time, which is why agents work detached.
- The script lives at `/home/abel/agent-worktree.sh` (owned by abel).
- Override the base dir for testing: `AGENT_WORKTREES_DIR=/tmp/wt-worktrees`.
