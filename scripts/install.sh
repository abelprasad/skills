#!/bin/bash
# install.sh — copy-install the vendored skills from this repo into every
# detected agent harness (macOS / Linux).
#
#   bash scripts/install.sh --all                      # install all skills
#   bash scripts/install.sh --skills local-ponytail,summary
#   bash scripts/install.sh --list                     # show what would install
#
# No flags: lists skills + harnesses, then asks once (TTY only).
# A harness is detected when its skills folder exists; nothing is ever
# created for a harness that isn't there. Install = copy the whole skill
# folder into <harness-skills>/<skill-name>/, replacing any older copy.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Vendored skills: everything Abel made + the liked skills whose license
# permits vendoring. Link-only skills (see skills/README.md) are never here.
discover_skills() {
  for d in "$REPO_ROOT"/skills/made/*/ "$REPO_ROOT"/skills/liked/*/; do
    [ -f "${d}SKILL.md" ] && basename "$d"
  done | sort -u
}

HARNESSES="$HOME/.claude/skills $HOME/.cursor/skills $HOME/.copilot/skills $HOME/.agents/skills $HOME/.gemini/skills $HOME/.config/opencode/skills"

skill_source() { # $1=name -> path or empty
  if [ -d "$REPO_ROOT/skills/made/$1" ]; then echo "$REPO_ROOT/skills/made/$1"; return 0; fi
  if [ -d "$REPO_ROOT/skills/liked/$1" ]; then echo "$REPO_ROOT/skills/liked/$1"; return 0; fi
  echo ""
}

list() {
  echo "Skills in this repo:"
  for s in $(discover_skills); do echo "  $s"; done
  echo "Detected harnesses:"
  for h in $HARNESSES; do [ -d "$h" ] && echo "  $h"; done
}

install_all() { # $1 = comma list or "ALL"
  local wanted="$1" n=0
  for h in $HARNESSES; do
    [ -d "$h" ] || continue
    for s in $(discover_skills); do
      if [ "$wanted" != "ALL" ]; then
        case ",$wanted," in *",$s,"*) ;; *) continue ;; esac
      fi
      rm -rf "$h/$s"
      cp -r "$(skill_source "$s")" "$h/$s"
      echo "[PASS] $s -> $h"
      n=$((n + 1))
    done
  done
  [ "$n" -gt 0 ] || echo "[SKIP] no detected harnesses, nothing installed"
  echo "Installed $n skill folder(s)."
}

case "${1:-}" in
  --list) list ;;
  --all) install_all "ALL" ;;
  --skills) [ -n "${2:-}" ] || { echo "usage: $0 --skills a,b,c" >&2; exit 1; }; install_all "$2" ;;
  --help|-h) sed -n '2,10p' "$0" ;;
  *)
    list
    if [ -t 0 ]; then
      printf "Install all skills into all detected harnesses? [y/N] "
      read -r ans
      case "$ans" in y|Y|yes|YES) install_all "ALL" ;; *) echo "Nothing installed." ;; esac
    else
      echo "Nothing installed. Re-run with --all or --skills a,b."
    fi
    ;;
esac
