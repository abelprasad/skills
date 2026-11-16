"""Watch your calendar and record meetings automatically. Local only.

Reads your meetings from the calendar source set in config.yaml:
  - outlook (default): reads your Outlook calendar directly via COM
    while Outlook is open on Windows. No export, no new login, no
    cloud app. Falls back to the .ics file when Outlook is not open.
  - ics: reads a local .ics calendar export (set calendar_file).

It polls every minute, and for each meeting:
  - starts capture.py 1 minute before the meeting starts,
  - stops it when the meeting ends,
  - runs transcribe.py on the recording, which writes the note and,
    by default, deletes the recording.

It never joins a meeting and never talks to any service. In outlook mode
it only reads the calendar, never creates, edits, or deletes anything.

Usage:
    python calendar_watcher.py            # watch forever (Ctrl+C to stop)
    python calendar_watcher.py --once     # check now, print what would happen
    python calendar_watcher.py --list     # list today's meetings
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

import yaml

HERE = Path(__file__).parent


def parse_ics_datetime(value: str) -> datetime | None:
    """Parse an ICS DTSTART/DTEND value. Handles UTC (Z) and local times."""
    value = value.strip()
    for fmt in ("%Y%m%dT%H%M%SZ", "%Y%m%dT%H%M%S", "%Y%m%d"):
        try:
            dt = datetime.strptime(value, fmt)
            if fmt.endswith("Z"):
                dt = dt.replace(tzinfo=timezone.utc)
            elif dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except ValueError:
            continue
    return None


def parse_ics(path: Path) -> list[dict]:
    """Minimal .ics parser (stdlib only). Returns events with summary/start/end."""
    events: list[dict] = []
    current: dict | None = None
    text = path.read_text(encoding="utf-8", errors="ignore")
    # Unfold continuation lines (lines starting with a space belong to the previous).
    lines: list[str] = []
    for raw in text.splitlines():
        if raw.startswith((" ", "\t")) and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    for line in lines:
        if line == "BEGIN:VEVENT":
            current = {}
        elif line == "END:VEVENT":
            if current and "start" in current and "end" in current:
                events.append(current)
            current = None
        elif current is not None:
            if line.startswith("SUMMARY:"):
                current["summary"] = line[len("SUMMARY:"):].strip()
            elif line.startswith("DTSTART"):
                _, _, val = line.partition(":")
                dt = parse_ics_datetime(val)
                if dt:
                    current["start"] = dt
            elif line.startswith("DTEND"):
                _, _, val = line.partition(":")
                dt = parse_ics_datetime(val)
                if dt:
                    current["end"] = dt
    return events


def todays_meetings(events: list[dict], now: datetime, min_minutes: int) -> list[dict]:
    """Meetings today (or already started and not yet ended), long enough to keep."""
    out = []
    for ev in events:
        if ev["end"] <= now:
            continue
        if (ev["end"] - ev["start"]).total_seconds() < min_minutes * 60:
            continue
        # All-day events have a midnight-to-midnight span of >= 24h; skip them.
        if (ev["end"] - ev["start"]).total_seconds() >= 24 * 3600:
            continue
        out.append(ev)
    return sorted(out, key=lambda e: e["start"])


def get_outlook_events(cfg: dict) -> list[dict]:
    """Read today's meetings from Outlook via COM (Windows only).

    Read-only: never creates, edits, or deletes anything. Raises
    RuntimeError with a plain-English reason when Outlook is not
    available, so the caller can fall back to the .ics file.
    """
    try:
        import win32com.client  # type: ignore  # Windows only (pywin32)
    except ImportError:
        raise RuntimeError(
            "Outlook calendar is not available on this computer "
            "(no win32com). Install pywin32 on Windows to use it."
        )
    try:
        outlook = win32com.client.Dispatch("Outlook.Application")
        namespace = outlook.GetNamespace("MAPI")
        profile = str(cfg.get("outlook_profile", "") or "").strip()
        if profile:
            namespace.Logon(profile)
        calendar = namespace.GetDefaultFolder(9)  # 9 = olFolderCalendar
        items = calendar.Items
        items.IncludeRecurrences = True
        items.Sort("[Start]")
    except Exception as exc:  # Outlook closed, profile missing, COM error, ...
        raise RuntimeError(f"Could not read the Outlook calendar: {exc}")

    local_tz = datetime.now().astimezone().tzinfo
    tomorrow_local = (
        datetime.now().astimezone(local_tz) + timedelta(days=1)
    ).replace(hour=0, minute=0, second=0, microsecond=0)
    tomorrow_utc = tomorrow_local.astimezone(timezone.utc)

    events: list[dict] = []
    try:
        for item in items:
            try:
                start = item.Start
                end = item.End
            except Exception:
                continue
            if start is None or end is None:
                continue
            if start.tzinfo is None:
                start = start.replace(tzinfo=local_tz)
            if end.tzinfo is None:
                end = end.replace(tzinfo=local_tz)
            start = start.astimezone(timezone.utc)
            end = end.astimezone(timezone.utc)
            if start >= tomorrow_utc:
                break  # Items are sorted by start; nothing later is today.
            events.append({
                "summary": str(getattr(item, "Subject", "") or "Meeting"),
                "start": start,
                "end": end,
            })
            if len(events) >= 500:
                break
    except Exception as exc:
        raise RuntimeError(f"Could not read the Outlook calendar: {exc}")
    return events


def load_events(cfg: dict) -> tuple[list[dict], str]:
    """Load events from the configured calendar source.

    Returns (events, source_label). Never crashes the watcher: when the
    configured source is unavailable it prints a plain-English line and
    falls back to the .ics file, then to an empty list.
    """
    source = str(cfg.get("calendar_source", "outlook") or "outlook").strip().lower()
    cal_file = Path(cfg.get("calendar_file", "calendar.ics"))
    if source == "outlook":
        try:
            return get_outlook_events(cfg), "Outlook"
        except RuntimeError as exc:
            print(f"{exc}")
            if cal_file.exists():
                print("Outlook is not open, using your calendar file instead.")
                return parse_ics(cal_file), "calendar file"
            print(
                "Outlook is not open and there is no calendar file. "
                "Waiting for the next check."
            )
            return [], "none"
    # ics mode (or anything else: fall back to the file, same as before).
    if not cal_file.exists():
        print(f"Calendar file not found: {cal_file}")
        print(
            "Export your calendar as an .ics file and set "
            "calendar_file in config.yaml."
        )
        return [], "none"
    return parse_ics(cal_file), "calendar file"


def safe_filename(title: str) -> str:
    keep = [c if c.isalnum() or c in (" ", "-", "_") else "_" for c in title]
    return "".join(keep).strip().replace(" ", "-")[:60] or "meeting"


def run_meeting(event: dict, cfg: dict) -> None:
    """Record one meeting, then transcribe it. Blocks until the meeting ends."""
    start = event["start"]
    end = event["end"]
    title = event.get("summary", "Meeting")
    now = datetime.now(timezone.utc)
    wait = (start - timedelta(minutes=int(cfg.get("start_early_minutes", 1))) - now).total_seconds()
    if wait > 0:
        print(f"Next meeting '{title}' starts at {start}. Waiting {wait / 60:.1f} min.")
        time.sleep(wait)

    rec_dir = Path(cfg.get("recordings_dir", "recordings"))
    stamp = start.strftime("%Y-%m-%d_%H%M")
    wav = rec_dir / f"{stamp}_{safe_filename(title)}.wav"
    duration = max(60, (end - datetime.now(timezone.utc)).total_seconds())
    print(f"Recording '{title}' for up to {duration / 60:.0f} min -> {wav}")
    subprocess.run(
        [sys.executable, str(HERE / "capture.py"), "--out", str(wav),
         "--duration", str(duration)],
        check=False,
    )
    if not wav.exists():
        print(f"No recording made for '{title}'. Skipping transcription.")
        return
    notes_dir = Path(cfg.get("notes_dir", "notes"))
    out = notes_dir / f"{stamp}_{safe_filename(title)}.md"
    print(f"Transcribing '{title}'...")
    subprocess.run(
        [sys.executable, str(HERE / "transcribe.py"), str(wav),
         "--title", title, "--out", str(out)],
        check=False,
    )
    print(f"Done. Note: {out}")


def load_config() -> dict:
    with open(HERE / "config.yaml", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def main(argv: list[str] | None = None) -> int:
    # Line-buffered output so status lines show at once in a console
    # or a log file, instead of sitting in a buffer while watching.
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true", help="Check once and exit")
    parser.add_argument("--list", action="store_true", help="List meetings and exit")
    args = parser.parse_args(argv)

    cfg = load_config()
    now = datetime.now(timezone.utc)
    events, source = load_events(cfg)
    meetings = todays_meetings(events, now, int(cfg.get("min_meeting_minutes", 5)))

    if args.list:
        if not meetings:
            print(f"No meetings found ({source}).")
        for ev in meetings:
            print(f"{ev['start'].strftime('%H:%M')}–{ev['end'].strftime('%H:%M')}  {ev.get('summary', 'Meeting')}")
        return 0

    if args.once:
        nxt = meetings[0] if meetings else None
        if nxt:
            print(f"Next meeting: '{nxt.get('summary')}' at {nxt['start']} (ends {nxt['end']}).")
        else:
            print(f"No upcoming meetings ({source}).")
        return 0

    print(f"Watching {source} — {len(meetings)} upcoming meeting(s). Ctrl+C to stop.")
    while True:
        now = datetime.now(timezone.utc)
        events, source = load_events(cfg)
        meetings = todays_meetings(events, now, int(cfg.get("min_meeting_minutes", 5)))
        if meetings:
            run_meeting(meetings[0], cfg)
        time.sleep(60)


if __name__ == "__main__":
    sys.exit(main())
