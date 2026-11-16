# agent-worktree

One task, one worktree, one agent. Parallel Claude Code agents must never share files, so each agent gets its own detached git worktree.

## Use

```sh
# create (ref defaults to HEAD; pass a branch or sha to pin it)
agent-worktree.sh add /home/abel/dogsrun pspca-adapter

# start the agent, interactive in tmux
tmux new-session -d -s wt-dogsrun-pspca-adapter \
  "cd /home/abel/worktrees/dogsrun-pspca-adapter && /home/abel/.npm-global/bin/claude"
tmux attach -t wt-dogsrun-pspca-adapter

# status
agent-worktree.sh list

# merge back (from the main checkout; sha = worktree tip)
git -C /home/abel/worktrees/dogsrun-pspca-adapter log --oneline -3
git -C /home/abel/dogsrun merge <sha>

# clean up (refuses with uncommitted changes unless --force)
agent-worktree.sh rm dogsrun-pspca-adapter
```

## Rules

- Never two agents on the same files. One worktree per agent, always.
- Never edit the main checkout while an agent owns a worktree of that repo.
- Merge back only after reading the diff.
- Delete the worktree after merging. Stale worktrees rot.
- Long jobs run detached in tmux; never inject into a live Claude session.
- Run everything as abel, never as root, or files end up root-owned.

Full guide: [WORKTREES.md](WORKTREES.md). Override the base dir for testing: `AGENT_WORKTREES_DIR=/tmp/wt-worktrees`.
