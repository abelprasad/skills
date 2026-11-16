#!/usr/bin/env bash
# agent-worktree.sh — one task, one worktree, one agent.
#
# Parallel Claude Code agents must never share files. This creates a
# detached git worktree per task under /home/abel/worktrees/ so each
# agent gets its own checkout of the same repo.
#
# Usage:
#   agent-worktree.sh add <repo-path> <task-name> [ref]  # ref defaults to HEAD
#   agent-worktree.sh list
#   agent-worktree.sh rm <name> [--force]                # name is <repo>-<task>
#   agent-worktree.sh help
#
# Run as abel. Override the base dir for testing:
#   AGENT_WORKTREES_DIR=/tmp/wt-worktrees agent-worktree.sh add ...

set -euo pipefail

BASE="${AGENT_WORKTREES_DIR:-/home/abel/worktrees}"
CLAUDE="/home/abel/.npm-global/bin/claude"

die() { echo "error: $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
usage:
  agent-worktree.sh add <repo-path> <task-name> [ref]   create detached worktree (ref defaults to HEAD)
  agent-worktree.sh list                                list worktrees in /home/abel/worktrees
  agent-worktree.sh rm <name> [--force]                 remove a worktree (<repo>-<task>)
  agent-worktree.sh help
EOF
}

repo_name() {
  local r="${1%/}"
  r="${r##*/}"
  r="${r%.git}"
  printf '%s' "$r"
}

cmd_add() {
  local repo="$1" task="$2" ref="${3:-HEAD}"
  [[ "$task" =~ ^[A-Za-z0-9._-]+$ ]] || die "bad task name: $task (letters, digits, . _ - only)"
  [ -d "$repo" ] || die "repo not found: $repo"
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "not a git repo: $repo"
  local name="$(repo_name "$repo")-$task"
  local path="$BASE/$name"
  [ -e "$path" ] && die "worktree already exists: $path (rm it first or pick another task name)"
  mkdir -p "$BASE"
  git -C "$repo" worktree add --detach "$path" "$ref"
  local sha
  sha="$(git -C "$path" rev-parse --short HEAD)"
  echo "worktree: $path"
  echo "repo:     $repo"
  echo "ref:      $sha (detached)"
  echo
  echo "start an agent, interactive in tmux:"
  echo "  tmux new-session -d -s wt-$name \"cd $path && $CLAUDE\""
  echo "  tmux attach -t wt-$name"
  echo
  echo "or one-shot:"
  echo "  cd $path && $CLAUDE -p \"<task>\""
  echo
  echo "when the agent is done, merge back from $repo:"
  echo "  git -C $path log --oneline -3   # tip sha"
  echo "  git -C $repo merge <sha>"
  echo "  agent-worktree.sh rm $name"
}

cmd_list() {
  mkdir -p "$BASE"
  local found=0
  for d in "$BASE"/*/; do
    [ -d "$d" ] || continue
    found=1
    local n="${d%/}"; n="${n##*/}"
    local head dirty=""
    head="$(git -C "$d" rev-parse --short HEAD 2>/dev/null || echo "?")"
    [ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ] && dirty=" (uncommitted changes)"
    printf '%s  %s%s\n' "$n" "$head" "$dirty"
  done
  if [ "$found" -eq 0 ]; then
    echo "no worktrees in $BASE"
  fi
}

cmd_rm() {
  local name="$1"
  shift
  local force=0
  [ "${1:-}" = "--force" ] && force=1
  local path="$BASE/$name"
  [ -d "$path" ] || die "no such worktree: $path"
  # Main repo = parent of the common git dir.
  local common
  common="$(git -C "$path" rev-parse --git-common-dir 2>/dev/null)" \
    || die "cannot find main repo for $path"
  case "$common" in
    /*) ;;
    *) common="$(cd "$path" && pwd)/$common" ;;
  esac
  local main
  main="$(dirname "$common")"
  if [ -n "$(git -C "$path" status --porcelain)" ] && [ "$force" -eq 0 ]; then
    die "uncommitted changes in $path — commit them or re-run with --force"
  fi
  git -C "$main" worktree remove --force "$path"
  echo "removed: $path"
}

case "${1:-help}" in
  add)
    [ $# -ge 3 ] || { usage; exit 1; }
    cmd_add "$2" "$3" "${4:-HEAD}"
    ;;
  list)
    cmd_list
    ;;
  rm|clean|remove)
    [ $# -ge 2 ] || { usage; exit 1; }
    cmd_rm "$2" "${3:-}"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "unknown command: $1" >&2
    usage
    exit 1
    ;;
esac
