#!/bin/bash
# CodeGraph + RTK setup — Linux / macOS
# Interactive installer: run with no flags and pick what to install from a
# menu, like the Claude Code installer. One command, then choose.
#
#   bash install.sh
#
# Automation (no prompts):
#   bash install.sh --all                      # both, no prompt
#   bash install.sh --codegraph-only           # CodeGraph only
#   bash install.sh --rtk-only                 # RTK only
#   bash install.sh --all --yes                # both, skip the download confirm
#   bash install.sh --all --repos ~/github/dogsrun,https://github.com/you/repo
#   bash install.sh --all --scan-repos ~/github
#   bash install.sh --all --reinit             # re-init repos already indexed
#   bash install.sh --all --skip-repos         # skip the repo step entirely
#   bash install.sh --all --skills-all         # also install all bundled skills into every detected AI setup
#   bash install.sh --all --skills-skip        # skip the Skills step entirely
#   bash install.sh --all --skills claude,cursor  # skills into those setups only
#   bash install.sh --all --skills-all --include-claude-mem --include-security-audit  # + opt-in external installs
#
# Work laptop = work only, no personal repos on it: the repo step is optional
# and skipped by default (press Enter at the prompt). On a work laptop, run
# `codegraph init` yourself in the repo you are working in. When you do opt
# in, the full picker is available: folder scan, individual paths, and
# GitHub clone URLs.
#
# What it installs:
#   CodeGraph — pre-indexed local code knowledge graph (100% local, Rust kernel)
#   RTK       — Rust CLI that compresses shell output 60-90% before agent context
# Wiring: CodeGraph as an MCP server, RTK as a PreToolUse hook on Bash.
# RTK never blocks a command and never hides output (see `rtk bypass`).
# No repo paths, company names, or secrets are hardcoded here.
# Personal GitHub repos only: the repo picker never asks for, clones, or
# initializes company code. Company code stays out.
set -e

say() { printf '\n==> %s\n' "$1"; }

# --- Results table -----------------------------------------------------------
RESULTS=()
add_result() { # $1=PASS|SKIP|FAIL  $2=step  $3=detail
  RESULTS+=("$1 | $2 | $3")
  printf '[%s] %s - %s\n' "$1" "$2" "$3"
}
print_results() {
  printf '\n=== Summary ===\n'
  printf '%s\n' "${RESULTS[@]}"
  local fails=0
  for r in "${RESULTS[@]}"; do case "$r" in FAIL*) fails=$((fails + 1));; esac; done
  if [ "$fails" -eq 0 ]; then
    printf 'ALL CHECKS PASSED.\n'
  else
    printf '%s check(s) FAILED.\n' "$fails"
  fi
  return "$fails"
}

# --- Defaults / flags ---------------------------------------------------------
MODE=""            # codegraph | rtk | both
CONFIRM=yes        # prompt before downloading (interactive mode only)
REPOS_CSV=""
SCAN_DIR=""
REINIT=0
SKIP_REPOS=0     # --skip-repos: skip the repo step entirely
SKILLS_ALL=0
SKILLS_SKIP=0
SKILLS_CSV=""
SKILL_NAMES_CSV=""
INCLUDE_CLAUDE_MEM=0
INCLUDE_SECURITY_AUDIT=0
INTERACTIVE=0

# Shared Skills step (skills-install.sh next to this file). Sourced so
# install_skills_step can append to RESULTS via add_result. If the file is
# missing, the step reports SKIP instead of failing the install.
SKILLS_SCRIPT="$(dirname "$0")/skills-install.sh"
[ -f "$SKILLS_SCRIPT" ] && . "$SKILLS_SCRIPT"

usage() {
  echo "Usage: bash install.sh [--all | --codegraph-only | --rtk-only] [--yes] [--repos <csv>] [--scan-repos <dir>] [--reinit] [--skip-repos] [--skills-all | --skills-skip | --skills <csv>] [--skill-names <csv>] [--include-claude-mem] [--include-security-audit]"
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all) MODE=both ;;
    --codegraph-only) MODE=codegraph ;;
    --rtk-only) MODE=rtk ;;
    --yes) CONFIRM=no ;;
    --repos) REPOS_CSV="$2"; shift ;;
    --repos=*) REPOS_CSV="${1#--repos=}" ;;
    --scan-repos) SCAN_DIR="$2"; shift ;;
    --scan-repos=*) SCAN_DIR="${1#--scan-repos=}" ;;
    --reinit) REINIT=1 ;;
    --skip-repos) SKIP_REPOS=1 ;;
    --skills-all) SKILLS_ALL=1 ;;
    --skills-skip) SKILLS_SKIP=1 ;;
    --skills) SKILLS_CSV="$2"; shift ;;
    --skills=*) SKILLS_CSV="${1#--skills=}" ;;
    --skill-names) SKILL_NAMES_CSV="$2"; shift ;;
    --skill-names=*) SKILL_NAMES_CSV="${1#--skill-names=}" ;;
    --include-claude-mem) INCLUDE_CLAUDE_MEM=1 ;;
    --include-security-audit) INCLUDE_SECURITY_AUDIT=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown flag: $1"; usage ;;
  esac
  shift
done

# --- Interactive menu (only called from main, when no selection flag given) ------
show_menu() {
  echo ""
  echo "=== CodeGraph + RTK setup ==="
  echo "100% local tools. CodeGraph indexes your code on this machine;"
  echo "RTK only compresses command output. Nothing leaves the machine."
  echo ""
  echo "  [1] CodeGraph only   - code knowledge graph for your agents"
  echo "  [2] RTK only         - compress shell output before agent context"
  echo "  [3] Both (default)   - CodeGraph + RTK"
  echo "  [4] Quit"
  echo ""
  printf 'Pick one [1-4, default 3]: '
  local choice=""
  read -r choice || true
  case "$choice" in
    1) MODE=codegraph ;;
    2) MODE=rtk ;;
    4) echo "Cancelled. Nothing installed."; exit 0 ;;
    *) MODE=both ;;
  esac
}

# --- 0. Prerequisites -------------------------------------------------------
command -v curl >/dev/null 2>&1 || { echo "curl is required but not found. Install curl and re-run."; exit 1; }

# --- 1. Install CodeGraph ---------------------------------------------------
install_codegraph() {
  say "Installing CodeGraph..."
  if command -v codegraph >/dev/null 2>&1; then
    add_result "SKIP" "CodeGraph installed" "codegraph already on PATH ($(codegraph --version 2>/dev/null || echo unknown))"
    return 0
  fi
  curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  if command -v codegraph >/dev/null 2>&1; then
    add_result "PASS" "CodeGraph installed" "$(codegraph --version 2>/dev/null || echo installed)"
  else
    add_result "FAIL" "CodeGraph installed" "codegraph not on PATH after install; add \$HOME/.local/bin to PATH and re-run"
    return 1
  fi
}

# --- 2. Install RTK ----------------------------------------------------------
install_rtk() {
  say "Installing RTK..."
  if command -v rtk >/dev/null 2>&1; then
    add_result "SKIP" "RTK installed" "rtk already on PATH ($(rtk --version 2>/dev/null || echo unknown))"
    return 0
  fi
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  if command -v rtk >/dev/null 2>&1; then
    add_result "PASS" "RTK installed" "$(rtk --version 2>/dev/null || echo installed)"
  else
    add_result "FAIL" "RTK installed" "rtk not on PATH after install; add \$HOME/.local/bin to PATH and re-run"
    return 1
  fi
}

# --- 3. Wire CodeGraph into your agents --------------------------------------
wire_codegraph() {
  say "Wiring CodeGraph into Claude Code (and any other detected agents)..."
  if codegraph install --yes; then
    add_result "PASS" "CodeGraph wired" "MCP server added to your agents"
  else
    add_result "FAIL" "CodeGraph wired" "re-run 'codegraph install --yes' in a new terminal"
  fi
}

# --- 4. Wire RTK into Claude Code ---------------------------------------------
wire_rtk() {
  say "Wiring RTK into Claude Code..."
  rtk init -g || true
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$HOME/.claude/settings.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        d = json.load(f)
except FileNotFoundError:
    d = {}
hooks = d.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])
entry = {"matcher": "Bash", "hooks": [{"type": "command", "command": "rtk hook claude"}]}
if not any(e.get("matcher") == "Bash" and any(h.get("command") == "rtk hook claude" for h in e.get("hooks", [])) for e in pre):
    pre.append(entry)
    with open(path, "w") as f:
        json.dump(d, f, indent=2)
    print("RTK PreToolUse hook merged into " + path)
else:
    print("RTK hook already present in " + path)
PYEOF
    add_result "PASS" "RTK wired" "PreToolUse hook in ~/.claude/settings.json (or already present)"
  else
    echo "python3 not found; add the RTK hook manually to ~/.claude/settings.json:"
    echo '  { "hooks": { "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "rtk hook claude" }] }] } }'
    add_result "SKIP" "RTK wired" "python3 missing, manual hook step printed above"
  fi
}

# --- Repo picker (CodeGraph only) ---------------------------------------------
# Personal GitHub repos only. Never prompt for, clone, or init company code.
scan_repos() { # $1=parent folder -> prints one repo path per line
  local parent="$1"
  [ -d "$parent" ] || return 0
  find "$parent" -maxdepth 3 -type d -name .git 2>/dev/null | while read -r gitdir; do
    dirname "$gitdir"
  done
}

repo_name_from_url() { # $1=url -> repo name without .git
  local base
  base="$(basename "${1%/}")"
  echo "${base%.git}"
}

init_repo() { # $1=repo path -> PASS/FAIL with file/node counts
  local repo="$1"
  local name
  name="$(basename "$repo")"
  if [ -d "$repo/.codegraph" ] && [ "$REINIT" -eq 0 ]; then
    add_result "SKIP" "codegraph init: $name" "already initialized (use --reinit to rebuild)"
    return 0
  fi
  (cd "$repo" && codegraph init >/tmp/codegraph-init-out.txt 2>&1)
  local rc=$?
  local counts=""
  if [ $rc -eq 0 ]; then
    counts="$(cd "$repo" && codegraph status 2>/dev/null | grep -oiE '[0-9,]+ files|[0-9,]+ nodes' | tr '\n' ' ' || true)"
    [ -z "$counts" ] && counts="index built"
    add_result "PASS" "codegraph init: $name" "$counts"
  else
    add_result "FAIL" "codegraph init: $name" "codegraph init failed; see /tmp/codegraph-init-out.txt"
  fi
}

pick_repos() {
  # Work laptop = work only, no personal repos on it: this step is optional
  # and skipped by default. Personal repos only on personal machines; on a
  # work laptop, run `codegraph init` yourself in the repo you are working
  # in — do not paste repo names or paths here.
  if [ "$SKIP_REPOS" -eq 1 ]; then
    echo "Repo step skipped (--skip-repos). Run codegraph init later in any repo yourself."
    return 0
  fi
  if [ "$INTERACTIVE" -eq 1 ]; then
    echo "Point CodeGraph at repos? (optional, press Enter to skip. On a work laptop, skip this. You can run codegraph init later in any repo yourself.)"
    echo "Personal repos only on personal machines; on a work laptop, run codegraph init yourself in the repo you are working in, do not paste repo names or paths here."
    printf 'Point CodeGraph at repos? [y/N, Enter skips]: '
    local optin=""
    read -r optin || true
    case "$optin" in
      [yY]*) : ;;
      *) echo "Skipped. Run codegraph init later in any repo yourself."; return 0 ;;
    esac
  elif [ -z "$REPOS_CSV" ] && [ -z "$SCAN_DIR" ]; then
    echo "No repos given. Repo step skipped — run codegraph init later in any repo yourself."
    return 0
  fi
  say "Point CodeGraph at your repos (personal GitHub repos only — company code stays out)."
  local selected=()
  local clone_base="${HOME}/github"

  # (a) Parent folder scan
  local scan_target="$SCAN_DIR"
  if [ -z "$scan_target" ] && [ "$INTERACTIVE" -eq 1 ]; then
    printf 'Scan a parent folder for repos? (e.g. ~/github) [y/N]: '
    local do_scan=""
    read -r do_scan || true
    if [[ "$do_scan" =~ ^[yY] ]]; then
      printf 'Parent folder to scan [default %s]: ' "$clone_base"
      read -r scan_target || true
      [ -z "$scan_target" ] && scan_target="$clone_base"
    fi
  fi
  if [ -n "$scan_target" ]; then
    local found=()
    while IFS= read -r line; do [ -n "$line" ] && found+=("$line"); done < <(scan_repos "$scan_target")
    if [ "${#found[@]}" -eq 0 ]; then
      echo "No git repos found under $scan_target."
    else
      echo "Found ${#found[@]} repos under $scan_target:"
      local i=1
      for r in "${found[@]}"; do echo "  [$i] $r"; i=$((i + 1)); done
      if [ "$INTERACTIVE" -eq 1 ]; then
        printf 'Pick all (a), numbers separated by spaces (e.g. 1 3), or none (n) [default a]: '
        local pick=""
        read -r pick || true
        case "$pick" in
          [nN]*) : ;;
          ""|[aA]*) selected+=("${found[@]}") ;;
          *) for n in $pick; do
               if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#found[@]}" ]; then
                 selected+=("${found[$((n - 1))]}")
               fi
             done ;;
        esac
      else
        selected+=("${found[@]}")
      fi
    fi
  fi

  # (b) Individual paths / URLs, one per line, blank to finish
  if [ -n "$REPOS_CSV" ]; then
    IFS=',' read -ra extra <<< "$REPOS_CSV"
    for e in "${extra[@]}"; do
      e="$(echo "$e" | xargs)"
      [ -n "$e" ] && selected+=("$e")
    done
  elif [ "$INTERACTIVE" -eq 1 ]; then
    echo "Add repos one by one — a local path or a GitHub clone URL. Blank line to finish."
    while true; do
      printf 'Repo path or URL (blank to finish): '
      local entry=""
      read -r entry || break
      [ -z "$entry" ] && break
      selected+=("$entry")
    done
  fi

  # Clone URLs, then init each selected repo
  for entry in "${selected[@]}"; do
    local path="$entry"
    if [[ "$entry" == *"://"* ]] || [[ "$entry" == git@* ]]; then
      local rname
      rname="$(repo_name_from_url "$entry")"
      printf 'Clone %s into [%s/%s] (Enter to accept, or type another folder): ' "$entry" "$clone_base" "$rname"
      local dest=""
      if [ "$INTERACTIVE" -eq 1 ]; then read -r dest || true; fi
      [ -z "$dest" ] && dest="$clone_base/$rname"
      if [ -d "$dest/.git" ]; then
        echo "Already cloned at $dest."
      else
        mkdir -p "$(dirname "$dest")"
        if git clone "$entry" "$dest"; then
          path="$dest"
        else
          add_result "FAIL" "clone: $rname" "git clone failed for $entry"
          continue
        fi
      fi
      path="$dest"
    fi
    if [ -d "$path/.git" ]; then
      init_repo "$path"
    else
      add_result "SKIP" "codegraph init: $entry" "not a git repo, skipped"
    fi
  done
  [ "${#selected[@]}" -eq 0 ] && echo "No repos selected. You can index a project any time with: cd <your-project> && codegraph init"
}

# --- Main ----------------------------------------------------------------------
main() {
  # Interactive menu (only when no selection flag was given)
  if [ -z "$MODE" ]; then
    INTERACTIVE=1
    show_menu
  fi

  # Confirm before downloading (interactive mode only)
  if [ "$INTERACTIVE" -eq 1 ] && [ "$CONFIRM" = "yes" ]; then
    case "$MODE" in
      codegraph) echo "This will install: CodeGraph" ;;
      rtk)       echo "This will install: RTK" ;;
      both)      echo "This will install: CodeGraph + RTK" ;;
    esac
    printf 'Continue? [Y/n]: '
    ans=""
    read -r ans || true
    case "$ans" in
      [nN]|[nN][oO]) echo "Cancelled. Nothing installed."; exit 0 ;;
    esac
  fi

  export PATH="$HOME/.local/bin:$PATH"
  case "$MODE" in
    codegraph)
      install_codegraph
      wire_codegraph
      pick_repos
      ;;
    rtk)
      install_rtk
      wire_rtk
      ;;
    both)
      install_codegraph
      install_rtk
      wire_codegraph
      wire_rtk
      pick_repos
      ;;
  esac

  # --- Skills: install bundled skills into every detected AI setup -----------
  if declare -F install_skills_step >/dev/null 2>&1; then
    install_skills_step "$INTERACTIVE" "$SKILLS_ALL" "$SKILLS_SKIP" "$SKILLS_CSV" "$SKILL_NAMES_CSV" "$INCLUDE_CLAUDE_MEM" "$INCLUDE_SECURITY_AUDIT"
  else
    add_result "SKIP" "Skills" "skills-install.sh not found next to installer"
  fi

  say "Verifying..."
  if [ "$MODE" != "rtk" ] && command -v codegraph >/dev/null 2>&1; then
    codegraph --version
  fi
  if [ "$MODE" != "codegraph" ] && command -v rtk >/dev/null 2>&1; then
    rtk --version
    rtk gain || true
  fi

  print_results
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    say "Done. Restart your agent, then explore a project:"
    echo "  codegraph explore <what you want to understand>"
    echo "  rtk gain              # shows tokens saved so far"
  else
    echo "Some steps failed. Fix the failures above and re-run (it skips what is already done)."
  fi
  return "$rc"
}

# Only run main when executed as a script (not when sourced for testing).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
