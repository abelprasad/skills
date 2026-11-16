# Set up local AI on the work laptop

Everything runs on the laptop. No accounts, no API keys, nothing in the cloud. This installs Ollama + a set of local models + faster-whisper for transcription — the stack the meeting note taker and local code help run on.

## What you need

- A Windows laptop with 64 GB RAM (the script sizes the models for that).
- About **5 GB free disk** for Minimal, **~15 GB** for Recommended on a CPU-only laptop, **~19 GB** for Recommended with a GPU, **~25 GB** for Full. The script scans the machine first and checks this up front — it stops with the number if there is not enough room.
- An internet connection for the downloads. Expect roughly 20–60 minutes on a fast office connection for the CPU set (~12 GB); the GPU set (~22 GB) takes longer. Model pulls resume if they get interrupted, so a dropped connection is not fatal — just re-run the script.

## Steps

1. **Download the zip** (`work-laptop-local-ai.zip`) and unzip it to `C:\local-ai`. The folder contains `setup-local-ai.ps1`, `skills-install.ps1`, a `skills/` folder, `README.md`, `models.md`, and this file.
2. **Run the script.** In File Explorer, right-click `setup-local-ai.ps1` and choose **Run with PowerShell**. Admin is **not** required, but running as Administrator is fine too.
   - If Windows blocks it with an execution-policy error, run this from a PowerShell window instead (from inside `C:\local-ai`):
     ```powershell
     powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1
     ```
   - Or allow it for your user once, then run normally:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
     ```
   - A menu appears — pick a model set (see below). It asks for confirmation before downloading anything.
3. **Wait.** The script prints each step as it goes. Model downloads are the slow part — do not close the window.

## The scan (runs first)

Before the menu, the script scans the machine and prints a short summary,
then a one-line list of the models that can be installed:

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

Each line has the tag, parameters, download size, context length, speed
note, capability note, a brain joke, and whether it fits this machine.
Models that do not fit are marked NOT RECOMMENDED with the reason, never
hidden — on a CPU-only machine the vision line reads `NOT RECOMMENDED on
this machine: needs a GPU`.

## The menu

```
Pick a model set:
  [1] Recommended (default) - qwen3.5:4b + qwen3:8b + coder + embeddings
  [2] Minimal                - qwen3.5:4b + embeddings only (smallest download)
  [3] Full                   - Recommended + vision (qwen2.5vl:7b, GPU only)
  [4] Custom                 - toggle coder / embeddings / vision one by one
  [5] Quit
```

- **Recommended** is the default: everything the note taker and local code help need (~12 GB on CPU, ~16 GB on GPU).
- **Minimal** is the smallest download (~5 GB): just the instruct model and embeddings.
- **Full** adds the vision model (GPU only, ~22 GB total). On a CPU-only laptop it warns and skips vision.
- **Custom** asks you about coder, embeddings, and vision one by one.
- Python + faster-whisper (transcription) are included in every set.

No-prompt runs (same result, no menu):

```powershell
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -All      # Recommended set
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Minimal  # instruct + embeddings only
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Full     # Recommended + vision (GPU only)
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Yes      # skip the download confirm
```
4. **Check the summary.** When it finishes it prints a table with PASS / SKIP / FAIL for every step, and either `ALL CHECKS PASSED. Local AI is ready.` (exit code 0) or the number of failed checks (exit code 1). If anything failed, fix it from the troubleshooting section below and re-run the script — it is idempotent and skips everything already done.

## What the script does, step by step

1. **Ollama** — skips if `ollama` is already on PATH. Otherwise installs it with winget (`Ollama.Ollama`), falling back to the official `OllamaSetup.exe` installer with silent flags.
2. **Ollama service** — checks the API on `http://localhost:11434`; starts `ollama serve` in the background if it is not running.
3. **GPU detection** — reads `nvidia-smi`. 8 GB+ VRAM picks the large model set; anything else (or `-CpuOnly`) uses the CPU set.
4. **Model pulls** — pulls the model set you picked in the menu, one at a time, skipping any already present:
   - Recommended: `qwen3.5:4b` (instruct / summaries), `qwen3:8b` (small / fast), `qwen2.5-coder:7b` (code, 14b on GPU), `nomic-embed-text` (embeddings).
   - Minimal: `qwen3.5:4b`, `nomic-embed-text` only.
   - Full: Recommended plus the optional vision model `qwen2.5vl:7b` (GPU only; skip it with `-SkipVision`).
   - Custom: `qwen3.5:4b` always, plus the models you picked by number from the list (e.g. `1 2 4 7`).
5. **Python + faster-whisper** — uses existing Python if present, otherwise installs Python 3.12 with winget; then pip-installs `faster-whisper` 1.2.1.
6. **Whisper smoke test** — generates a 1-second test tone, loads the Whisper `small` model (~470 MB download on first run), transcribes it.
7. **Test prompt** — asks the instruct model to reply with exactly `LOCAL AI OK` through the local API and checks the reply.
8. **Skills step** — finds the AI setups on the machine (Claude Code, Cursor, Copilot, Codex, Gemini CLI, OpenCode) and offers the bundled skills. See "Skills step" below.

Optional switches (no-prompt runs):

```powershell
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -All        # Recommended set, no menu
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Minimal    # instruct + embeddings only
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Full       # Recommended + vision (GPU only)
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Yes        # skip the download confirm
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -CpuOnly    # force the CPU model set
powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkipVision # skip the vision model
```

## Skills step (runs after the models)

After the models install, the installer finds the AI setups on the machine
and asks which skills to install into them. It prints DETECTED / not found
per setup with the path checked. A setup that is not detected is skipped —
no folder is created for it.

One menu lists each skill with a one-line description — pick all, pick by
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

The step also prints whether CodeGraph and RTK are installed, so one menu
covers tools + skills. Bundled skills ship in the pack under `skills/`
(offline, exact versions Abel already uses). Optional external installs
are opt-in only and each asks for confirmation first: **claude-mem**
(`npx claude-mem install --setup defer`; setup deferred to first session;
observer trial asks for a payment method) and **security-audit** (`npx
skills add https://github.com/cloudflare/security-audit-skill --skill
security-audit --global`). Both need Node.js.

No-prompt runs: `-SkillsAll` (all bundled skills), `-SkillsSkip` (skip),
`-Skills "claude,cursor"` (those setups only).

## How to verify it worked

Open a new PowerShell window (close and reopen it once after install so PATH refreshes) and run:

```powershell
ollama list              # shows the installed models
ollama run qwen3.5:4b    # chat with the main model
ollama run qwen2.5-coder:7b   # code model (14b on GPU machines)
```

If the final summary said `ALL CHECKS PASSED`, it is ready. The meeting note taker uses faster-whisper for transcription and the instruct model for summaries; the code model answers code questions locally.

## Troubleshooting

| Problem | Fix |
|---|---|
| Script blocked: "running scripts is disabled on this system" | Run with `powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1`, or set `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass` once. Do not set it machine-wide. |
| `ollama` not recognized in a new terminal | Close and reopen the terminal; the installer updates PATH for new sessions only. Or start Ollama from the Start menu once. |
| `ollama list` fails / connection refused | Start Ollama from the Start menu once, or run `ollama serve` in a terminal. |
| A model pull fails halfway | Re-run the script; pulls resume and skip what is already there. |
| Not enough disk space | The script fails up front with the free-space number. Free space on C:, or set a user environment variable `OLLAMA_MODELS` to another drive (e.g. `D:\ollama-models`) **before** running the script and restart the terminal. Existing models do not move automatically. |
| `winget` not found | Update App Installer from the Microsoft Store; the script falls back to the Ollama installer download automatically. |
| Python install fails | Install Python 3.12 from python.org, close and reopen the terminal, re-run the script. |
| Whisper test fails | Check the error in the output; usually it is the ~470 MB model download failing on a bad connection — re-run the script. |
| Test prompt fails | Check Ollama is running (`ollama list` works) and the instruct model pulled. Re-run the script. |

## Files in this pack

- `setup-local-ai.ps1` — the setup script (run once, re-runnable)
- `skills-install.ps1` — the shared Skills step (called by the setup script)
- `skills/` — bundled skills installed by the Skills step (i-have-adhd, local-ponytail, summary, repo-packaging, qa-agent, local-ui-ux-pro-max)
- `README.md` — what gets installed, how to add models later, what each part feeds
- `models.md` — the exact model list, sizes, RAM needs, GPU vs CPU choice
- `SETUP-ON-LAPTOP.md` — this file
