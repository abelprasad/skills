"""Transcribe a meeting recording, keep only the important moments, and
write a short note. Local only: faster-whisper for transcription and
Ollama on localhost for the summary. No audio or text leaves the machine.

Usage:
    python transcribe.py recordings/my-meeting.wav
    python transcribe.py recordings/my-meeting.wav --out notes/my-meeting.md
    python transcribe.py recordings/my-meeting.wav --title "Weekly sync"
    python transcribe.py --test-ranking   # proves the skip-the-rest rule

The ranking rule (see README): every chunk of transcript is scored, and
only chunks scoring >= keep_score are summarized. Everything else is
dropped before the summary model ever sees it.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

import requests
import yaml

# ---------------------------------------------------------------------------
# Ranking — pure function, no models needed. This is what test_ranking.py
# exercises, and it is the heart of the "only important moments" rule.
# ---------------------------------------------------------------------------

DECISION_PATTERNS = [
    r"\bdecided\b", r"\bagreed\b", r"\bapproved\b", r"\bwe will\b",
    r"\blet'?s go with\b", r"\bship it\b", r"\bgoing with\b",
    r"\bdecision is\b", r"\bwe'?re doing\b",
]

ACTION_PATTERNS = [
    r"\baction item\b", r"\bto[ -]?do\b", r"\bfollow up\b",
    r"\byou will\b", r"\bI will\b", r"\bby (monday|tuesday|wednesday|thursday|friday)\b",
    r"\bowner\b", r"\bassigned to\b", r"\bdeadline\b", r"\bdue (by|on)\b",
]

SIGNAL_PATTERNS = [
    r"\b\d{1,2} (jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b",
    r"\b(q1|q2|q3|q4)\b", r"\b\d+%\b", r"\bblocker\b", r"\brisk\b",
]

QUESTION_ANSWERED = re.compile(r"\?.*\b(yes|no|we will|let'?s)\b", re.IGNORECASE)


def score_chunk(text: str) -> tuple[int, list[str]]:
    """Score one transcript chunk. Returns (score, reasons)."""
    lowered = text.lower()
    score = 0
    reasons: list[str] = []
    for pat in DECISION_PATTERNS:
        if re.search(pat, lowered):
            score += 3
            reasons.append(f"decision ({pat.strip(chr(92) + 'b')})")
            break
    for pat in ACTION_PATTERNS:
        if re.search(pat, lowered):
            score += 3
            reasons.append("action item")
            break
    for pat in SIGNAL_PATTERNS:
        if re.search(pat, lowered):
            score += 2
            reasons.append("date/number/blocker")
            break
    if QUESTION_ANSWERED.search(text):
        score += 1
        reasons.append("answered question")
    return score, reasons


def rank_segments(segments: list[dict], keep_score: int = 3) -> list[dict]:
    """Keep only the segments that score >= keep_score.

    Each segment is {"start": seconds, "end": seconds, "text": str}.
    Returns the kept segments, each with "score" and "reasons" added.
    """
    kept: list[dict] = []
    for seg in segments:
        score, reasons = score_chunk(seg["text"])
        if score >= keep_score:
            kept.append({**seg, "score": score, "reasons": reasons})
    return kept


def chunk_segments(segments: list[dict], chunk_seconds: int = 30) -> list[dict]:
    """Group Whisper segments into ~chunk_seconds chunks for ranking."""
    chunks: list[dict] = []
    current: list[dict] = []
    start = None
    for seg in segments:
        if start is None:
            start = seg["start"]
        current.append(seg)
        if seg["end"] - start >= chunk_seconds:
            chunks.append({
                "start": start,
                "end": seg["end"],
                "text": " ".join(s["text"].strip() for s in current),
            })
            current = []
            start = None
    if current:
        chunks.append({
            "start": start if start is not None else 0,
            "end": current[-1]["end"],
            "text": " ".join(s["text"].strip() for s in current),
        })
    return chunks


# ---------------------------------------------------------------------------
# Transcription (local faster-whisper) and summary (local Ollama).
# ---------------------------------------------------------------------------

def transcribe_audio(audio_path: Path, model_name: str = "small") -> list[dict]:
    from faster_whisper import WhisperModel

    model = WhisperModel(model_name, device="auto", compute_type="int8")
    segments_iter, _info = model.transcribe(str(audio_path), beam_size=5)
    return [
        {"start": round(s.start, 1), "end": round(s.end, 1), "text": s.text.strip()}
        for s in segments_iter
        if s.text.strip()
    ]


def summarize_with_ollama(
    kept: list[dict], title: str, ollama_url: str, model: str
) -> dict:
    """Ask the local LLM to turn the kept chunks into a structured note.

    Only the kept chunks are sent. If Ollama is not reachable, fall back to
    a plain extractive note so the meeting is still recorded.
    """
    transcript = "\n".join(
        f"[{k['start']:.0f}s] {k['text']}" for k in kept
    )
    prompt = (
        "You are writing a short meeting note. Use ONLY the transcript below. "
        "Do not invent anything. Output exactly these sections, in this order:\n"
        "Summary: one sentence about what was decided.\n"
        "Decisions: one bullet per decision, or 'None'.\n"
        "Action items: one bullet per item as 'What - Who - By when', or 'None'.\n"
        "Other important: dates, numbers, or names mentioned, or 'None'.\n\n"
        f"Meeting: {title}\n\nTranscript:\n{transcript}"
    )
    try:
        resp = requests.post(
            f"{ollama_url.rstrip('/')}/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
            timeout=300,
        )
        resp.raise_for_status()
        return {"summary_text": resp.json().get("response", "").strip(), "source": "ollama"}
    except Exception as exc:  # noqa: BLE001 - fallback is the point
        fallback = (
            f"Summary: {kept[0]['text'] if kept else 'No decisions recorded.'}\n\n"
            "Decisions:\n"
            + "\n".join(f"- {k['text']}" for k in kept)
            + "\n\nAction items:\nNone recorded by the fallback.\n\n"
            "Other important:\nNone.\n"
        )
        return {"summary_text": fallback, "source": f"fallback ({exc})"}


def write_note(
    title: str, kept: list[dict], summary: dict, out_path: Path,
    kept_count: int, total_count: int,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    header = (
        f"# {title}\n\n"
        f"_Kept {kept_count} of {total_count} transcript chunks. "
        f"The rest was skipped as not important. "
        f"Summary source: {summary['source']}._\n\n"
    )
    out_path.write_text(header + summary["summary_text"].strip() + "\n", encoding="utf-8")


def load_config() -> dict:
    cfg_path = Path(__file__).parent / "config.yaml"
    with open(cfg_path, encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("audio", nargs="?", help="Recording file (.wav)")
    parser.add_argument("--out", help="Note file to write")
    parser.add_argument("--title", default="Meeting note", help="Meeting title")
    parser.add_argument("--test-ranking", action="store_true",
                        help="Run the fake-transcript ranking test and exit")
    args = parser.parse_args(argv)

    if args.test_ranking:
        from test_ranking import run_test
        return run_test()

    if not args.audio:
        parser.error("give a recording file, or use --test-ranking")
    audio_path = Path(args.audio)
    if not audio_path.exists():
        print(f"Could not find the recording: {audio_path}")
        return 2

    cfg = load_config()
    keep_score = int(cfg.get("keep_score", 3))
    chunk_seconds = int(cfg.get("chunk_seconds", 30))

    print("Turning the recording into text (local Whisper)...")
    segments = transcribe_audio(audio_path, cfg.get("whisper_model", "small"))
    chunks = chunk_segments(segments, chunk_seconds)
    kept = rank_segments(chunks, keep_score)
    print(f"Kept {len(kept)} of {len(chunks)} chunks. The rest is skipped.")

    summary = summarize_with_ollama(
        kept, args.title, cfg.get("ollama_url", "http://127.0.0.1:11434"),
        cfg.get("llm_model", "qwen3.5:4b"),
    )
    out_path = Path(args.out) if args.out else (
        Path(cfg.get("notes_dir", "notes")) / (audio_path.stem + ".md")
    )
    write_note(args.title, kept, summary, out_path, len(kept), len(chunks))
    print(f"Note written to {out_path}")

    if not cfg.get("keep_audio", False):
        audio_path.unlink(missing_ok=True)
        print("Recording deleted (keep_audio is false).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
