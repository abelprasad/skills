# Meeting Note Taker — private, local only

A note taker for work meetings that listens, picks out only the important
moments, and writes them down for you. Nothing leaves your laptop.

## What it does, in plain English

1. It watches your calendar. When a meeting starts, it starts recording.
   When the meeting ends, it stops.
2. It turns the recording into text, on your laptop, with a local
   transcription model. No audio is sent anywhere.
3. It reads the text and keeps only the important parts: decisions,
   action items, dates, and who is doing what. Everything else is skipped.
4. It writes a short note for that meeting and saves it on your laptop.
5. It deletes the recording after the text is made, unless you turn that off.

## Privacy, in plain English

- The recording never leaves your laptop. There is no account, no cloud,
  no upload.
- The notes are plain files in the `notes/` folder on your laptop.
- The recording is deleted right after it is turned into text. If you want
  to keep recordings, set `keep_audio: true` in `config.yaml`.
- It does not join the meeting as a participant. It records the sound
  coming out of your own laptop speakers and your microphone, the same way
  a voice recorder would. It does not tell anyone it is recording.

## What you need

- Windows, macOS, or Linux. This was built for a Windows work laptop.
- Python 3.10 or newer.
- Ollama running on your laptop with the local AI models already installed
  (see the local AI setup pack: `qwen3.5:4b` for summaries,
  faster-whisper `small` for transcription).
- Outlook installed and open on your Windows laptop (for the live
  calendar, the default). Or a calendar file as the fallback. See
  "Calendar" below.

## Install (first run, about 2 minutes)

Windows — double-click `run-notes.bat`, or in PowerShell:

```powershell
.\run-notes.bat
```

macOS / Linux:

```bash
bash run-notes.sh
```

The first run creates its own setup folder (`.venv`), installs the parts it
needs, and checks that Ollama is running on your laptop. After that, just
run it again.

## Run it

```powershell
.\run-notes.bat
```

It keeps running in the background, watching your calendar. When a meeting
starts it records, when it ends it writes the note. Press Ctrl+C to stop it.

To process one recording by hand (no calendar needed):

```powershell
python transcribe.py recordings\my-meeting.wav --out notes\my-meeting.md
```

## Where the notes land

`notes/YYYY-MM-DD_HHMM_<meeting-title>.md` — one file per meeting, with:

- A one-line summary of what was decided.
- Decisions (with who decided them, when known).
- Action items: what, who, by when.
- Anything else important: dates, numbers, names.

Nothing else from the meeting is written down. Small talk, status updates
with no decision, and repeated points are skipped on purpose.

## Calendar

### Live calendar (Outlook) — the default

The watcher reads your Outlook calendar directly, while Outlook is open
on your Windows laptop. No export, no new login, no cloud app, no admin.
It only reads the calendar; it never creates, edits, or deletes anything.

What you need: Outlook installed and open, and `calendar_source: outlook`
in `config.yaml` (already the default). If you use a non-default Outlook
profile, set `outlook_profile` in `config.yaml` to its name, otherwise
leave it blank.

It starts recording 1 minute before a meeting starts and stops when the
meeting ends. Meetings shorter than 5 minutes are skipped. All-day events
are skipped.

### Fallback — the .ics file

When Outlook is not open, the watcher prints a plain line saying so and
uses your calendar file instead, if you have one. Set
`calendar_source: ics` in `config.yaml` to use the file all the time and
never try Outlook. Export your calendar to an `.ics` file and set
`calendar_file` in `config.yaml`. Re-export it when your meetings change.
If neither Outlook nor the file is available, the watcher prints a plain
line and waits for the next check. It never crashes.

## Settings — config.yaml

| Setting | What it does |
|---|---|
| `platform` | `teams`, `zoom`, `meet`, or `manual`. Picks the capture notes below. The recording itself is the same on every platform. |
| `calendar_source` | `outlook` (default, live) or `ics` (file only). See "Calendar" above. |
| `calendar_file` | Path to your exported `.ics` calendar file. Used in `ics` mode and as the fallback when Outlook is not open. |
| `outlook_profile` | Outlook profile name, or blank for your default profile. Only used in `outlook` mode. |
| `notes_dir` | Where notes are saved. Default `notes/`. |
| `recordings_dir` | Where recordings go while they are being processed. Default `recordings/`. |
| `keep_audio` | `false` (default): delete the recording after the text is made. `true`: keep it. |
| `whisper_model` | Transcription model. Default `small`. |
| `llm_model` | Summary model in Ollama. Default `qwen3.5:4b`. |
| `ollama_url` | Local Ollama address. Default `http://127.0.0.1:11434`. Never change this to a web address. |
| `min_meeting_minutes` | Skip meetings shorter than this. Default `5`. |
| `audio_device` | Leave blank to use the default. Set it only if recording picks the wrong device. |

## Platform notes — pick one in config.yaml

### Microsoft Teams

- Capture: system audio loopback (WASAPI on Windows). Teams plays meeting
  audio through your speakers, so loopback hears it. Your microphone is
  recorded on a second track so your own voice is captured too.
- Turn on: in Windows Sound settings, allow apps to use your microphone.
  No Teams setting needs to change, and no bot joins the meeting.
- What breaks: if you join with a headset, loopback hears the headset
  output, which is fine. If Teams is set to a different output device than
  your default, set `audio_device` in `config.yaml` to that device.

### Zoom

- Capture: same as Teams, system audio loopback plus microphone.
- Turn on: nothing special in Zoom. Do not turn on Zoom's cloud recording
  or its AI companion; this tool replaces both, locally.
- What breaks: Zoom's "original sound" setting does not matter for this.
  If you use a USB headset, loopback follows the headset output.

### Google Meet

- Capture: same as Teams and Zoom, system audio loopback plus microphone.
  Meet runs in the browser, and the browser's audio goes through the
  system output, so loopback hears it.
- Turn on: allow the browser to use your microphone when Meet asks.
- What breaks: if you have two browsers open with sound, loopback hears
  both. Close other tabs with sound before the meeting.

### Manual

- Capture: same loopback plus microphone, but the calendar watcher is off.
  Start a recording by hand with `python capture.py --duration 3600` and
  then run `transcribe.py` on the file. Use this if your calendar export
  is not set up yet.

## How the "only important moments" rule works

Every 30-second chunk of the transcript is scored:

- **+3** — a decision: "decided", "agreed", "approved", "we will", "let's go with", "ship it".
- **+3** — an action item: "action", "to do", "follow up", "you will", "by Friday", "owner".
- **+2** — a date or deadline, a number that is a target, a named person
  attached to a task.
- **+1** — a question that got answered, a risk or blocker named.
- **0** — everything else: greetings, status with no change, small talk,
  repeated points.

Only chunks scoring **3 or more** are summarized. The rest are never sent
to the summary model and never written to the note. The test in
`test_ranking.py` proves this: 5 fake chunks in, only the 2 with decisions
come out.

## Files in this folder

| File | What it is |
|---|---|
| `README.md` | This file. |
| `config.yaml` | Your settings. Edit this, not the code. |
| `capture.py` | Records system audio + microphone to a WAV file. |
| `transcribe.py` | Turns a recording into text, ranks the chunks, summarizes only the important ones, writes the note. |
| `calendar_watcher.py` | Watches your Outlook calendar (live) or your `.ics` file and starts/stops recording. |
| `requirements.txt` | The parts it needs (faster-whisper, pyyaml, requests). |
| `run-notes.bat` / `run-notes.sh` | The one command to run it. |
| `examples/` | A fake transcript and the note it should produce. No real data. |

## Troubleshooting

- **"Ollama is not running"** — start Ollama, then run the script again.
  The note taker only talks to Ollama on your own laptop.
- **"No audio device"** — check the microphone is allowed in Windows
  privacy settings, and that a speaker or headset is connected.
- **"Outlook is not open, using your calendar file instead"** — open
  Outlook and the next check uses it live. If you would rather use the
  file all the time, set `calendar_source: ics` in `config.yaml`.
- **"Could not read the Outlook calendar"** — Outlook is installed but
  COM could not reach it. Close and reopen Outlook, then run the watcher
  again. If it keeps failing, set `calendar_source: ics` and use the
  `.ics` file instead.
- **"Outlook is not open and there is no calendar file"** — open Outlook,
  or export your calendar to an `.ics` file and set `calendar_file` in
  `config.yaml`. The watcher keeps waiting either way.
- **"No meetings found"** — check `calendar_source` in `config.yaml`.
  In `ics` mode, check `calendar_file` points at a real `.ics` file, and
  re-export your calendar.
- **A note is empty** — the meeting had no decisions or action items by
  the scoring rules above. That is the tool working as designed, not a bug.
- **It recorded but wrote nothing** — check `recordings/` for the WAV file
  and run `transcribe.py` on it by hand to see the error.

## What is NOT in here

No company data, no real meeting names, no real people, no repo names,
no passwords. The example files use fake names. You fill in your own
calendar file and your own settings on your laptop, and nothing about your
work ever leaves the machine.
