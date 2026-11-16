# Local AI — work laptop setup pack

Everything on the laptop, nothing in the cloud. Ollama for chat/code/vision models, faster-whisper for local transcription. Built for a Windows laptop with 64 GB RAM. No accounts, no API keys, no cloud services. Downloads come only from ollama.com, PyPI, and HuggingFace (Whisper weights).

## What gets installed

1. **Ollama for Windows** — the local model runner. Installs per-user, no admin needed. Runs in the background and serves models at `http://localhost:11434`.
2. **The model set** — see [models.md](models.md). Main instruct model for summaries and notes, a small fast model, a code model, an embeddings model for search, and (GPU only) a vision model for screenshots.
3. **Python 3.12** — only if Python is not already installed (via winget).
4. **faster-whisper 1.2.1** — local transcription, plus the Whisper `small` model (~470 MB) pre-downloaded.

## How to run it

1. Copy this folder to the work laptop.
2. Open PowerShell (Windows Terminal or PowerShell — right-click, Run as administrator is fine but not required).
3. Run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1
   ```
4. A menu appears — pick a model set, like the Claude Code installer:

   ```
   Pick a model set:
     [1] Recommended (default) - qwen3.5:4b + qwen3:8b + coder + embeddings
     [2] Minimal                - qwen3.5:4b + embeddings only (smallest download)
     [3] Full                   - Recommended + vision (qwen2.5vl:7b, GPU only)
     [4] Custom                 - toggle coder / embeddings / vision one by one
     [5] Quit
   ```

   It asks for confirmation before downloading anything. Python +
   faster-whisper (transcription) are included in every set.
5. Wait. Model downloads are the slow part (~5 GB for Minimal, ~15 GB for Recommended on CPU machines, ~19 GB on GPU machines, ~25 GB for Full). The script prints PASS / SKIP / FAIL for every step and a summary table at the end.
6. Re-run the script any time. It is idempotent: it skips Ollama, models, Python, and faster-whisper if they are already there, and only does what is missing.

No-prompt runs (same result, no menu):

```powershell
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -All       # Recommended set
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Minimal   # instruct + embeddings only
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Full      # Recommended + vision (GPU only)
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Yes       # skip the download confirm
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -CpuOnly   # force the CPU model set
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkipVision  # skip the vision model
```

## Scan first, then pick

The script scans the machine before showing the menu: OS + PowerShell
version, CPU + total/free RAM, GPU (name + VRAM, or "no GPU"), free disk,
Ollama installed/version or not, and already-pulled models. Then it shows
a short one-line list of the models that can be installed — one line per
model, with its size, context, speed, capability, a brain joke, and whether
it fits this machine. Models that do not fit are marked NOT RECOMMENDED
with the reason, never hidden.

Example scan + list (on a 64 GB laptop with an 8 GB GPU, nothing installed yet):

```
--- Machine scan ---
OS: Microsoft Windows 11 Pro | PowerShell 5.1.26100.1
CPU: 13th Gen Intel(R) Core(TM) i7-13800H (14 cores) | RAM: 64 GB total, 41 GB free
GPU: NVIDIA RTX 2000 Ada (8,192 MB VRAM)
Disk: 212 GB free on C:
Ollama: not installed

--- Models you can install (one line each) ---
[1] qwen3.5:4b (default) - 4B, 3.3-4GB, 256K ctx, fast on CPU, instruct + summaries, multimodal text+image, MMLU-Pro 79.1 | Brain of a sharp intern who never sleeps. | FITS
[2] qwen3:8b - 8B, 5.2GB, 256K ctx, brisk on CPU, faster on GPU, general chat + reasoning, stronger than the 4B | Brain of a grad student who actually read the docs. | FITS
[3] qwen3:14b - 14B, 9.3GB, 256K ctx, slow on CPU, wants a GPU, strongest general reasoning here | Brain of a senior who knows everything but thinks out loud slowly. | FITS
[4] qwen2.5-coder:7b - 7.6B, 4.7GB, 32K ctx, fast on CPU, code completion, explain, review | Brain of a junior dev who only speaks in code. | FITS
[5] qwen2.5-coder:14b - 14.7B, 9.0GB, 32K ctx, slow on CPU, wants a GPU, deeper code review | Brain of a staff engineer who reviews your PR at 3am. | FITS
[6] qwen2.5vl:7b - 7B, 6.0GB, 125K ctx, GPU only, describe screenshots, read UI | Brain of an art student who also reads screenshots. | FITS
[7] nomic-embed-text - 137M, 274MB, 2K ctx, instant, tiny, embeddings: search / RAG over notes | Brain of a librarian who remembers where every book is. | FITS
```

On a CPU-only machine the vision line reads `NOT RECOMMENDED on this
machine: needs a GPU` instead of `FITS`. Benchmark scores are
vendor-reported, not head-to-head (see models.md).

## Skills step (runs after the models)

After the models install, the installer offers a Skills step: it finds the
AI setups on the machine and installs bundled skills into them. It prints
DETECTED / not found per setup with the path checked (Claude Code
`~/.claude/skills`, Cursor `~/.cursor/skills`, GitHub Copilot
`~/.copilot/skills`, Codex `~/.agents/skills`, Gemini CLI
`~/.gemini/skills`, OpenCode `~/.config/opencode/skills`, Local shared
`~/.agents/skills`). A setup that is not detected is reported SKIP — no
directory is ever created for it.

One menu lists each skill with a one-line description. Pick all, pick by
number, or skip:

```
  [1] i-have-adhd - ADHD output protocol: action first, numbered steps, no preamble
  [2] local-ponytail - Laziest working solution: YAGNI, stdlib first, one line before fifty
  [3] summary - /summary: six-section handoff of everything talked and done
  [4] repo-packaging - ADRs, CLI product, privacy rule, dev-copy rule, presence
  [5] qa-agent - Checklist QA with screenshots + HTML report
  [6] local-ui-ux-pro-max - Design bundle: shadcn + Tailwind, brand, banners, slides
  [a] All bundled skills (default)
  [s] Skip skills
Optional external installs (never in All — pick by number only):
  [7] claude-mem - Persistent memory across sessions (external, needs Node.js)
  [8] security-audit - Multi-phase security audit skill (external, needs Node.js)
```

Bundled skills ship in the pack under `skills/` (offline, exact versions
Abel already uses — see `skills/README.md`). The step also prints whether
CodeGraph and RTK are installed, so one menu covers tools + skills.
Optional external installs: **claude-mem** (`npx claude-mem install
--setup defer`; needs Node.js; setup deferred to first session; observer
trial asks for a payment method) and **security-audit** (`npx skills add
https://github.com/cloudflare/security-audit-skill --skill security-audit
--global`; needs Node.js). Both are opt-in only, each asks for
confirmation first, and both commands were verified from their READMEs
Nov 16, 2026.

No-prompt runs:

```powershell
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillsAll    # all bundled skills, all detected setups
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillsSkip   # skip the Skills step
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Skills "claude,cursor"
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillNames "i-have-adhd,summary"
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillsAll -IncludeClaudeMem -IncludeSecurityAudit
```

## How to check it is working

```powershell
ollama list              # shows the installed models
ollama run qwen3.5:4b    # chat with the main model
ollama run qwen2.5-coder:7b   # code model (14b on GPU machines)
```

If `ollama` is not found in a new terminal, close and reopen the terminal (PATH refresh), or start Ollama from the Start menu once.

## Not Dell-only

The PowerShell script is the main path for the Dell work laptop, but the stack is not locked to it. The same models (qwen3.5:4b, qwen2.5-coder, nomic-embed-text, faster-whisper) run on any capable device via Ollama on macOS and Linux — same model names, same test prompt. On those systems, install Ollama from ollama.com, pull the models with `ollama pull`, and run the same checks. Only the .ps1 installer and winget steps are Windows-specific.

## How to add more models later

```powershell
ollama pull qwen3:32b
ollama run qwen3:32b
```

See [models.md](models.md) for bigger models that fit 64 GB RAM, and for the exact sizes.

## What this feeds

- **Meeting note taker:** faster-whisper transcribes locally, the instruct model (`qwen3.5:4b`) summarizes only the important parts. Audio never leaves the laptop.
- **Local code help:** `qwen2.5-coder` answers code questions and reviews code without sending it anywhere.
- **Search over notes:** `nomic-embed-text` powers retrieval over notes and docs.
- **QA agent:** `qwen2.5vl:7b` (GPU only) reads screenshots.

## Moving the models

By default Ollama stores models in `%USERPROFILE%\.ollama`. If C: is tight, set a user environment variable `OLLAMA_MODELS` to another drive (e.g. `D:\ollama-models`) **before** running the script, and restart the terminal. Existing models do not move automatically.

## Troubleshooting

| Problem | Fix |
|---|---|
| `ollama` not recognized after install | Close and reopen the terminal; the installer updates PATH for new sessions only |
| `ollama list` fails / connection refused | Start Ollama from the Start menu once, or run `ollama serve` in a terminal |
| A model pull fails halfway | Re-run the script; pulls resume and skip what is already there |
| Not enough disk space | The script checks free space on C: first and fails with the number; free space or set `OLLAMA_MODELS` to another drive |
| `winget` not found | Update App Installer from the Microsoft Store, or let the script fall back to the Ollama installer download |
| Python install fails | Install Python 3.12 from python.org, close and reopen the terminal, re-run the script |

## Files

- `setup-local-ai.ps1` — the setup script (run once, re-runnable)
- `skills-install.ps1` — the shared Skills step (called by the setup script)
- `skills/` — bundled skills installed by the Skills step (i-have-adhd, local-ponytail, summary, repo-packaging, qa-agent, local-ui-ux-pro-max)
- `models.md` — the exact model list, sizes, RAM needs, GPU vs CPU choice
- `README.md` — this file
