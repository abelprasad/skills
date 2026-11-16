# Models

Every tag below was verified against the Ollama library (ollama.com/library) on 2026-11-16. Sizes are the download sizes Ollama reports for the default (Q4_K_M) quant.

The main instruct model is **qwen3.5:4b** on both paths — the smallest most capable local model (3.3–4.0 GB, 256K context, text + image input, Apache 2.0, MMLU-Pro 79.1). The setup script picks a set automatically: **GPU** when `nvidia-smi` reports an NVIDIA GPU with 8 GB+ VRAM, otherwise **CPU**. The GPU/CPU split now only changes the code model size and whether the vision model is included. Run the script with `-CpuOnly` to force the CPU set.

## Portable: not Dell-only

The Windows PowerShell pack is the main path for the Dell work laptop, but nothing in the model list is Windows- or Dell-specific. The same models — qwen3.5:4b as the main instruct model, qwen2.5-coder for code, nomic-embed-text for embeddings — run on any capable device via Ollama on macOS and Linux too, with the same model names and the same test prompt (`Reply with exactly these three words: LOCAL AI OK`). On macOS or Linux, install Ollama from ollama.com, then `ollama pull qwen3.5:4b qwen3:8b qwen2.5-coder:7b nomic-embed-text` and run the same checks. The only Windows-specific parts are the .ps1 installer and winget; the models, the test, and the note-taker stack are portable.

## The set

| Model | Tag | Params | Disk | RAM to run | Context | Role |
|---|---|---:|---:|---:|---:|---|
| Qwen3.5 | `qwen3.5:4b` | 4.0B | 3.3–4.0 GB | ~4–5 GB | 256K | Main instruct model — meeting summaries, notes; also takes image input (both sets) |
| Qwen3 | `qwen3:8b` | 8.0B | 5.2 GB | ~6–7 GB | 256K | Small + fast — quick questions, drafts, titles; stronger reasoning than the 4B |
| Qwen3 | `qwen3:14b` | 14.0B | 9.3 GB | ~10–12 GB | 256K | Strongest general reasoning in the list — slow on CPU, best on GPU (Custom set) |
| Qwen2.5-Coder | `qwen2.5-coder:14b` | 14.7B | 9.0 GB | ~10–12 GB | 32K | Code help — explain, write, review code (GPU set) |
| Qwen2.5-Coder | `qwen2.5-coder:7b` | 7.6B | 4.7 GB | ~6–7 GB | 32K | Code help (CPU set) |
| Nomic Embed Text | `nomic-embed-text` | 137M | 274 MB | ~0.5 GB | 2K | Embeddings — search / RAG over notes and docs |
| Qwen2.5-VL | `qwen2.5vl:7b` | 7B + vision | 6.0 GB | ~7–8 GB | 125K | Vision — describe screenshots, read UI (GPU only, optional; may be redundant now that qwen3.5:4b takes image input — see below) |

Plus, outside Ollama:

| Model | Source | Size | Role |
|---|---|---:|---|
| faster-whisper `small` | HuggingFace (auto-downloaded by faster-whisper) | ~470 MB | Local transcription for the meeting note taker |

"RAM to run" is the model weight in memory plus ~1–2 GB of KV cache at a 4K context. Longer contexts use more KV cache. With 64 GB RAM you can keep two of these loaded at once; Ollama keeps one loaded by default and swaps on demand.

## Totals

- **GPU set (Recommended):** ~19 GB disk (qwen3.5:4b + qwen3:8b + coder 14b + embed)
- **CPU set (Recommended):** ~15 GB disk (qwen3.5:4b + qwen3:8b + coder 7b + embed)
- **Full (GPU only):** ~25 GB disk (Recommended + vision 7b)
- **Minimal:** ~5 GB disk (qwen3.5:4b + embed)
- Plus ~0.5 GB for the Whisper small model. Keep 5 GB free on top of that.

## Why these

- **Qwen3.5:4b** is the main model: the smallest most capable local model — 256K context, text + image input, Apache 2.0, MMLU-Pro 79.1 — so one model covers summaries, notes, and basic image input on both GPU and CPU. It replaces the old qwen3:14b/8b main-model split.
- **Qwen2.5-Coder** is the strongest small code model in the Ollama library at 7B/14B; it is trained for code completion, explanation, and review.
- **nomic-embed-text** is the standard Ollama embedding model (768-dim, good retrieval quality for its size).
- **Qwen2.5-VL 7b is now optional and possibly redundant:** qwen3.5:4b already takes image input. It stays in the GPU set for now — screenshot-heavy QA work may still prefer a dedicated vision model — but consider dropping it. Run the script with `-SkipVision` to leave it out.
- **faster-whisper `small`** is the sweet spot for meeting transcription: much more accurate than `tiny`/`base`, still fast on CPU (faster than real time on a modern laptop CPU with int8).

## Model intelligence comparison

Why qwen3.5:4b is the main pick — it leads the small-model field on the benchmarks that matter for notes, summaries, and code, while staying in the same 3–4 GB size class:

| Model | MMLU-Pro | GPQA Diamond | LiveCodeBench v6 | MMLU | Size | Context |
|---|---:|---:|---:|---:|---:|---:|
| **qwen3.5:4b** | **79.1** | **76.2** | **55.8** | — | 3.3–4.0 GB | 256K |
| Gemma 4 E4B | 69.4 | 58.6 | 52.0 | — | — | — |
| Phi-4 Mini 3.8B | 52.8 | — | — | 67.3 | 2.5 GB | — |
| Qwen3 4B | — | — | — | ~70 | 2.5 GB | 256K |

Scores are vendor-reported and directional, not head-to-head — different vendors test differently, so treat the gaps as approximate. The picture is still clear: qwen3.5:4b is ~10 points ahead of the next small model on MMLU-Pro and ~18 points ahead on GPQA Diamond. It is also Apache 2.0 licensed.

## Bigger models later (all tags verified)

If the GPU has 16 GB+ VRAM, or you want more quality on CPU with 64 GB RAM, these are one command away:

| Model | Tag | Params | Disk | Notes |
|---|---|---:|---:|---|
| Qwen3 | `qwen3:30b-a3b` | 30B MoE (3B active) | 19 GB | Better reasoning, still fast (MoE) |
| Qwen3 | `qwen3:32b` | 32B | 20 GB | Best quality that fits 64 GB RAM on CPU |
| Qwen2.5-Coder | `qwen2.5-coder:32b` | 32B | 20 GB | Bigger code model |
| Qwen2.5-VL | `qwen2.5vl:32b` | 32B | 21 GB | Bigger vision model (GPU only) |

```powershell
ollama pull qwen3:32b
ollama run qwen3:32b
```

## How the script chooses

The script scans the machine first (OS, CPU/RAM, GPU, free disk, Ollama
status, already-pulled models), prints the scan summary, then shows the
one-line model list (7 models, each one line: tag, params, size, context,
speed, capability, brain joke, and whether it fits this machine — models
that do not fit are marked NOT RECOMMENDED with the reason, never hidden).
Then the menu picks a set:

1. **Recommended (default)** — `qwen3.5:4b` + `qwen3:8b` + coder + `nomic-embed-text`.
2. **Minimal** — `qwen3.5:4b` + `nomic-embed-text` only (~5 GB).
3. **Full** — Recommended + `qwen2.5vl:7b` vision (GPU only; skipped with a warning when no GPU is present).
4. **Custom** — pick individual models from the list by number; `qwen3.5:4b` is always included (it is the main model).
5. **Automation flags** — `-All` (Recommended, no prompt), `-Minimal`, `-Full`, `-Yes` (skip the download confirm), `-CpuOnly`, `-SkipVision`. All flags keep working alongside the menu.

Example scan + list (see README.md for the full example). On a CPU-only
machine the vision line reads `NOT RECOMMENDED on this machine: needs a
GPU`; on a low-RAM machine the 14B models read `NOT RECOMMENDED on this
machine: needs 16GB+ RAM`.

The old automatic rules still apply inside a set:

1. `nvidia-smi` present and VRAM >= 8 GB → GPU set (coder 14b, vision included in Full).
2. Anything else (no GPU, small GPU, or `-CpuOnly`) → CPU set (coder 7b, no vision).
3. Main instruct (`qwen3.5:4b`), small fast model (`qwen3:8b`), and embeddings (`nomic-embed-text`) are pulled on both paths in the Recommended set.
4. `-SkipVision` skips the vision model even on GPU machines, including in Full and Custom.
