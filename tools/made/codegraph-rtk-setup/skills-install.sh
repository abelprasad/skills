#!/bin/bash
# skills-install.sh — shared Skills step for the setup packs (Linux / macOS).
# Source this file from a host installer, then call install_skills_step.
#   SKILLS_SCRIPT="$(dirname "$0")/skills-install.sh"; [ -f "$SKILLS_SCRIPT" ] && . "$SKILLS_SCRIPT"
#   install_skills_step "$INTERACTIVE" "$SKILLS_ALL" "$SKILLS_SKIP" "$SKILLS_CSV" "$SKILL_NAMES_CSV" "$INCLUDE_CLAUDE_MEM" "$INCLUDE_SECURITY_AUDIT"
# This file runs nothing on load except defining functions and tables.
# Host contract: the host defines add_result (status, step, detail) and a
# RESULTS array (both pack installers do). This file calls add_result and
# prints the same [PASS]/[SKIP]/[FAIL] lines.
#
# Skills source: a "skills" folder next to this file (bundled in the pack),
# one subfolder per skill with SKILL.md inside. Offered skills are exactly
# the folders found there — a skill with no source file is never offered.
# Install = copy the whole skill folder into <harness-skills>/<skill-name>/.
# i-have-adhd only: if the bundled copy is missing, it falls back to the
# upstream download (upstream text, not Abel's adopted version — reported
# as such in the result detail).
#
# External installs (never in "All", opt-in only): claude-mem and
# security-audit. Both need Node.js. Their commands were verified from
# their READMEs Nov 16, 2026 (see below). Each asks for confirmation
# before running, and prints what it needs first.
#
# Detection only: a harness that is not detected is reported SKIP and no
# directory is ever created for it. A harness is detected when its config
# folder exists on this machine or its command is on PATH.
#
# Harness skill folders (verified Nov 16, 2026):
#   Claude Code    ~/.claude/skills            (Anthropic docs)
#   Cursor         ~/.cursor/skills            (Cursor 2.4+ docs; also reads ~/.agents/skills)
#   GitHub Copilot ~/.copilot/skills           (Copilot CLI / VS Code personal path)
#   Codex          ~/.agents/skills            (OpenAI docs, current; legacy ~/.codex/skills used only if it already exists)
#   Gemini CLI     ~/.gemini/skills            (Google docs)
#   OpenCode       ~/.config/opencode/skills   (skills registries; some docs show singular "skill/" — plural is what the registries use)
#   Local (shared) ~/.agents/skills           (vendor-neutral folder Codex, Cursor and Gemini also read; same folder as Codex, deduped)
# VS Code project skills live in .github/skills inside each repo and are not
# covered by this machine-wide install.

SKILLS_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/skills"
I_HAVE_ADHD_UPSTREAM_URL="https://raw.githubusercontent.com/ayghri/i-have-adhd/main/skills/i-have-adhd/SKILL.md"

# Curated order for the menu. Only folders that actually exist are offered.
SKILL_ORDER="i-have-adhd local-ponytail summary repo-packaging qa-agent local-ui-ux-pro-max"

skill_desc() { # $1=skill name -> one-line description
  case "$1" in
    i-have-adhd) echo "ADHD output protocol: action first, numbered steps, no preamble" ;;
    local-ponytail) echo "Laziest working solution: YAGNI, stdlib first, one line before fifty" ;;
    summary) echo "/summary: six-section handoff of everything talked and done" ;;
    repo-packaging) echo "ADRs, CLI product, privacy rule, dev-copy rule, presence" ;;
    qa-agent) echo "Checklist QA with screenshots + HTML report" ;;
    local-ui-ux-pro-max) echo "Design bundle: shadcn + Tailwind, brand, banners, slides" ;;
    *) echo "" ;;
  esac
}

# Optional external installs. Commands verified from their READMEs Nov 16, 2026.
# Never included in "All". Each needs Node.js and an explicit pick + confirm.
#   claude-mem:     npx claude-mem install --setup defer
#                   (setup deferred to first session; observer trial asks for a
#                   payment method; memory lives in ~/.claude-mem)
#                   Source: https://github.com/thedotmack/claude-mem (Apache-2.0)
#   security-audit: npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global
#                   Source: https://github.com/cloudflare/security-audit-skill (MIT)
EXT_KEYS="claude-mem security-audit"

ext_display() { # $1=key
  case "$1" in
    claude-mem) echo "claude-mem" ;;
    security-audit) echo "security-audit" ;;
  esac
}
ext_desc() { # $1=key
  case "$1" in
    claude-mem) echo "Persistent memory across sessions" ;;
    security-audit) echo "Multi-phase security audit skill" ;;
  esac
}
ext_command() { # $1=key
  case "$1" in
    claude-mem) echo "npx claude-mem install --setup defer" ;;
    security-audit) echo "npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global" ;;
  esac
}
ext_notes() { # $1=key
  case "$1" in
    claude-mem) echo "Needs Node.js. Setup is deferred to your first session (no browser sign-in during install). The observer trial asks for a payment method; memory lives in ~/.claude-mem. Source: https://github.com/thedotmack/claude-mem (Apache-2.0)" ;;
    security-audit) echo "Needs Node.js. Installs via the skills CLI into your agents. Source: https://github.com/cloudflare/security-audit-skill (MIT)" ;;
  esac
}

# --- Harness table (parallel arrays, populated by detect_harnesses) --------------
HARNESS_KEYS=()
HARNESS_DISPLAYS=()
HARNESS_DIRS=()
HARNESS_DETECTED=()   # 1/0
HARNESS_NOTES=()

detect_harnesses() {
  HARNESS_KEYS=("claude" "cursor" "copilot" "codex" "gemini" "opencode" "local")
  HARNESS_DISPLAYS=("Claude Code" "Cursor" "GitHub Copilot" "Codex" "Gemini CLI" "OpenCode" "Local (shared)")
  local codex_dir="$HOME/.agents/skills"
  if [ ! -d "$codex_dir" ] && [ -d "$HOME/.codex/skills" ]; then
    codex_dir="$HOME/.codex/skills"
  fi
  HARNESS_DIRS=("$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.copilot/skills" "$codex_dir" "$HOME/.gemini/skills" "$HOME/.config/opencode/skills" "$HOME/.agents/skills")
  HARNESS_NOTES=(
    "checked ~/.claude and \`claude\` on PATH"
    "checked ~/.cursor and \`cursor\` on PATH"
    "checked ~/.copilot and \`copilot\` on PATH"
    "checked ~/.agents, ~/.codex and \`codex\` on PATH"
    "checked ~/.gemini and \`gemini\` on PATH"
    "checked ~/.config/opencode and \`opencode\` on PATH"
    "shared ~/.agents/skills, read by Codex, Cursor and Gemini"
  )
  local claude_d=0 cursor_d=0 copilot_d=0 codex_d=0 gemini_d=0 opencode_d=0
  { [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; } && claude_d=1
  { [ -d "$HOME/.cursor" ] || command -v cursor >/dev/null 2>&1; } && cursor_d=1
  { [ -d "$HOME/.copilot" ] || command -v copilot >/dev/null 2>&1; } && copilot_d=1
  { [ -d "$HOME/.agents" ] || [ -d "$HOME/.codex" ] || command -v codex >/dev/null 2>&1; } && codex_d=1
  { [ -d "$HOME/.gemini" ] || command -v gemini >/dev/null 2>&1; } && gemini_d=1
  { [ -d "$HOME/.config/opencode" ] || command -v opencode >/dev/null 2>&1; } && opencode_d=1
  local local_d=0
  { [ -d "$HOME/.agents/skills" ] || [ "$codex_d" -eq 1 ] || [ "$cursor_d" -eq 1 ] || [ "$gemini_d" -eq 1 ]; } && local_d=1
  HARNESS_DETECTED=("$claude_d" "$cursor_d" "$copilot_d" "$codex_d" "$gemini_d" "$opencode_d" "$local_d")
}

get_bundled_skills() { # prints one skill name per line, curated order, only if present
  local name
  for name in $SKILL_ORDER; do
    [ -f "$SKILLS_SOURCE_DIR/$name/SKILL.md" ] && echo "$name"
  done
}

get_skill_source() { # $1=skill name -> prints "bundled|<dir>" | "upstream|<dir>" | "missing|"
  local name="$1"
  if [ -f "$SKILLS_SOURCE_DIR/$name/SKILL.md" ]; then
    echo "bundled|$SKILLS_SOURCE_DIR/$name"
    return 0
  fi
  if [ "$name" = "i-have-adhd" ]; then
    local tmpdir="${TMPDIR:-/tmp}/i-have-adhd-skill"
    mkdir -p "$tmpdir" 2>/dev/null
    if curl -fsSL -o "$tmpdir/SKILL.md" "$I_HAVE_ADHD_UPSTREAM_URL" 2>/dev/null && [ -f "$tmpdir/SKILL.md" ]; then
      echo "upstream|$tmpdir"
      return 0
    fi
  fi
  echo "missing|"
}

install_skill_into_dir() { # $1=skill $2=source dir $3=origin $4=target dir $5=harness key
  local name="$1" src="$2" origin="$3" target="$4" hkey="$5"
  local dest="$target/$name"
  if mkdir -p "$dest" 2>/dev/null && cp -R "$src/." "$dest/" 2>/dev/null && [ -f "$dest/SKILL.md" ]; then
    local detail="$dest/SKILL.md"
    [ "$origin" = "upstream" ] && detail="$detail (upstream text, not Abel's adopted version)"
    add_result "PASS" "skill $name -> $hkey" "$detail"
  else
    add_result "FAIL" "skill $name -> $hkey" "copy did not land at $dest"
  fi
}

invoke_external_install() { # $1=key $2=interactive(1/0)
  local key="$1" interactive="$2"
  echo ""
  echo "Optional install: $(ext_display "$key") - $(ext_desc "$key")"
  echo "  Command: $(ext_command "$key")"
  echo "  $(ext_notes "$key")"
  if ! command -v node >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
    add_result "SKIP" "external install: $key" "Node.js not found on PATH; install Node.js first, then run the command above"
    return 0
  fi
  if [ "$interactive" -eq 1 ]; then
    printf 'Run this command now? [y/N]: '
    local ans=""
    read -r ans || true
    case "$ans" in
      [yY]*) : ;;
      *) echo "Skipped. Run it yourself any time:"; echo "  $(ext_command "$key")"
         add_result "SKIP" "external install: $key" "declined at prompt; command printed above"
         return 0 ;;
    esac
  fi
  # Split the verified command into words and run it (no eval of user input).
  # shellcheck disable=SC2086
  if $(ext_command "$key"); then
    add_result "PASS" "external install: $key" "ran: $(ext_command "$key")"
  else
    add_result "FAIL" "external install: $key" "exit code $? for: $(ext_command "$key")"
  fi
}

install_skills_step() {
  # $1=interactive(1/0) $2=skills_all(1/0) $3=skills_skip(1/0) $4=skills_csv
  # $5=skill_names_csv $6=include_claude_mem(1/0) $7=include_security_audit(1/0)
  local interactive="${1:-0}" skills_all="${2:-0}" skills_skip="${3:-0}"
  local skills_csv="${4:-}" skill_names_csv="${5:-}"
  local include_claude_mem="${6:-0}" include_security_audit="${7:-0}"

  echo ""
  echo "=== Skills ==="
  if [ "$skills_skip" -eq 1 ]; then
    echo "Skills step skipped (--skills-skip)."
    return 0
  fi

  # --- Tools in this pack (status only; install them from the main menu) -------
  echo "Tools in this pack:"
  if command -v codegraph >/dev/null 2>&1; then
    echo "  CodeGraph - installed ($(codegraph --version 2>/dev/null || echo unknown))"
  else
    echo "  CodeGraph - not installed (install from the main menu)"
  fi
  if command -v rtk >/dev/null 2>&1; then
    echo "  RTK       - installed ($(rtk --version 2>/dev/null || echo unknown))"
  else
    echo "  RTK       - not installed (install from the main menu)"
  fi

  local bundled=()
  while IFS= read -r line; do [ -n "$line" ] && bundled+=("$line"); done < <(get_bundled_skills)
  if [ "${#bundled[@]}" -eq 0 ]; then
    add_result "SKIP" "Skills" "no skill folders found in $SKILLS_SOURCE_DIR"
    return 0
  fi

  # --- Detect harnesses ------------------------------------------------------
  detect_harnesses
  echo "AI setups found on this machine:"
  local i=0
  for i in "${!HARNESS_KEYS[@]}"; do
    local state="not found"
    [ "${HARNESS_DETECTED[$i]}" -eq 1 ] && state="DETECTED"
    printf '  %-12s %s - %s (%s)\n' "${HARNESS_DISPLAYS[$i]}" "$state" "${HARNESS_DIRS[$i]}" "${HARNESS_NOTES[$i]}"
  done
  local detected_idx=()
  for i in "${!HARNESS_KEYS[@]}"; do
    [ "${HARNESS_DETECTED[$i]}" -eq 1 ] && detected_idx+=("$i")
  done
  if [ "${#detected_idx[@]}" -eq 0 ]; then
    add_result "SKIP" "Skills" "no AI setup detected on this machine (checked Claude Code, Cursor, Copilot, Codex, Gemini CLI, OpenCode)"
    return 0
  fi

  # --- Pick harnesses ---------------------------------------------------------
  local picked_h=()
  if [ "$skills_all" -eq 1 ]; then
    picked_h=("${detected_idx[@]}")
  elif [ -n "$skills_csv" ]; then
    local w
    IFS=',' read -ra wanted <<< "$skills_csv"
    for w in "${wanted[@]}"; do
      w="$(echo "$w" | xargs | tr '[:upper:]' '[:lower:]')"
      local found_i=-1
      for i in "${!HARNESS_KEYS[@]}"; do
        [ "${HARNESS_KEYS[$i]}" = "$w" ] && found_i="$i"
      done
      if [ "$found_i" -ge 0 ] && [ "${HARNESS_DETECTED[$found_i]}" -eq 1 ]; then
        picked_h+=("$found_i")
      elif [ "$found_i" -ge 0 ]; then
        add_result "SKIP" "skill install -> $w" "harness not detected on this machine"
      else
        add_result "SKIP" "skill install -> $w" "unknown harness name (use: claude, cursor, copilot, codex, gemini, opencode, local)"
      fi
    done
  elif [ "$interactive" -eq 0 ]; then
    echo "Skills step skipped in non-interactive mode. Re-run with --skills-all to install into every detected setup, or --skills claude,cursor to pick."
    return 0
  else
    echo ""
    echo "Install skills into:"
    echo "  [1] All detected setups (default)"
    echo "  [2] Pick setups by number"
    echo "  [3] Skip skills"
    printf 'Pick one [1-3, default 1]: '
    local choice=""
    read -r choice || true
    case "$choice" in
      3) echo "Skills step skipped."; return 0 ;;
      2)
        local j=0
        for idx in "${detected_idx[@]}"; do
          j=$((j + 1))
          echo "  [$j] ${HARNESS_DISPLAYS[$idx]} - ${HARNESS_DIRS[$idx]}"
        done
        printf 'Setup numbers, separated by spaces [default: all]: '
        local nums=""
        read -r nums || true
        if [ -z "$nums" ]; then
          picked_h=("${detected_idx[@]}")
        else
          local n
          for n in $nums; do
            if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#detected_idx[@]}" ]; then
              picked_h+=("${detected_idx[$((n - 1))]}")
            fi
          done
        fi
        ;;
      *) picked_h=("${detected_idx[@]}") ;;
    esac
  fi
  if [ "${#picked_h[@]}" -eq 0 ]; then
    echo "No setups picked. Skills step skipped."
    return 0
  fi

  # --- One Skills menu: bundled skills + optional external installs -----------
  local picked_s=()
  local picked_ext=()
  local ext_base="${#bundled[@]}"
  if [ -n "$skill_names_csv" ]; then
    local s
    IFS=',' read -ra wanted_s <<< "$skill_names_csv"
    for s in "${wanted_s[@]}"; do
      s="$(echo "$s" | xargs)"
      local ok=0
      for b in "${bundled[@]}"; do [ "$b" = "$s" ] && ok=1; done
      if [ "$ok" -eq 1 ]; then picked_s+=("$s"); else add_result "SKIP" "skill $s" "not in this pack"; fi
    done
    [ "$include_claude_mem" -eq 1 ] && picked_ext+=("claude-mem")
    [ "$include_security_audit" -eq 1 ] && picked_ext+=("security-audit")
  elif [ "$interactive" -eq 0 ] || [ "$skills_all" -eq 1 ] || [ -n "$skills_csv" ]; then
    picked_s=("${bundled[@]}")
    [ "$include_claude_mem" -eq 1 ] && picked_ext+=("claude-mem")
    [ "$include_security_audit" -eq 1 ] && picked_ext+=("security-audit")
  else
    echo ""
    echo "Which skills? (i-have-adhd first; the rest are Abel's own skills.)"
    local k=0
    for b in "${bundled[@]}"; do
      k=$((k + 1))
      echo "  [$k] $b - $(skill_desc "$b")"
    done
    echo "  [a] All bundled skills (default)"
    echo "  [s] Skip skills"
    echo "Optional external installs (never in All — pick by number only):"
    local e=0
    for key in $EXT_KEYS; do
      e=$((e + 1))
      echo "  [$((ext_base + e))] $(ext_display "$key") - $(ext_desc "$key") (external, needs Node.js)"
    done
    printf "Skill numbers, separated by spaces, 'a' for all bundled, 's' to skip [default a]: "
    local nums=""
    read -r nums || true
    if [ -z "$nums" ] || [ "$nums" = "a" ] || [ "$nums" = "A" ]; then
      picked_s=("${bundled[@]}")
    elif [ "$nums" = "s" ] || [ "$nums" = "S" ]; then
      echo "Skills step skipped."
      return 0
    else
      local n
      for n in $nums; do
        if [[ "$n" =~ ^[0-9]+$ ]]; then
          if [ "$n" -ge 1 ] && [ "$n" -le "${#bundled[@]}" ]; then
            picked_s+=("${bundled[$((n - 1))]}")
          elif [ "$n" -gt "${#bundled[@]}" ] && [ "$n" -le $(( ${#bundled[@]} + 2 )) ]; then
            local ei=$((n - ${#bundled[@]} - 1))
            local ek
            ek=$(echo "$EXT_KEYS" | cut -d' ' -f$((ei + 1)))
            picked_ext+=("$ek")
          fi
        fi
      done
    fi
  fi
  if [ "${#picked_s[@]}" -eq 0 ] && [ "${#picked_ext[@]}" -eq 0 ]; then
    echo "No skills picked. Skills step skipped."
    return 0
  fi

  # --- Install bundled skills (deduped by target folder: Codex and Local share one) ---
  local done_dirs=()
  local hi
  for hi in "${picked_h[@]}"; do
    local dir="${HARNESS_DIRS[$hi]}"
    local already=""
    for d in "${done_dirs[@]}"; do [ "$d" = "$dir" ] && already="$d"; done
    if [ -n "$already" ]; then
      for s in "${picked_s[@]}"; do
        add_result "SKIP" "skill $s -> ${HARNESS_KEYS[$hi]}" "same folder as an earlier harness, already installed"
      done
      continue
    fi
    done_dirs+=("$dir")
    for s in "${picked_s[@]}"; do
      local src_info src_origin src_dir
      src_info="$(get_skill_source "$s")"
      src_origin="${src_info%%|*}"
      src_dir="${src_info#*|}"
      if [ "$src_origin" = "missing" ]; then
        add_result "SKIP" "skill $s -> ${HARNESS_KEYS[$hi]}" "no source file in this pack and no upstream fallback"
        continue
      fi
      install_skill_into_dir "$s" "$src_dir" "$src_origin" "$dir" "${HARNESS_KEYS[$hi]}"
    done
  done

  # --- Optional external installs (opt-in only, each confirms first) --------------
  local ek
  for ek in "${picked_ext[@]}"; do
    invoke_external_install "$ek" "$interactive"
  done
  echo "Skills done. Restart the agent to pick up the new skill."
}
