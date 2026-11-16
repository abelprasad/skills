"""Record system audio + microphone to a WAV file. Local only.

On Windows this uses WASAPI loopback through sounddevice, so it hears the
meeting audio coming out of your speakers/headset, plus your microphone
on a second channel. It does not join the meeting and does not talk to
any service. On macOS/Linux it records the default input device only,
unless a loopback device is configured — see README.

Usage:
    python capture.py --out recordings/meeting.wav --duration 3600
    python capture.py --out recordings/meeting.wav   # records until Ctrl+C
    python capture.py --list-devices
"""

from __future__ import annotations

import argparse
import queue
import sys
import threading
import time
import wave
from pathlib import Path

SAMPLE_RATE = 16000
CHANNELS = 1


def list_devices() -> int:
    import sounddevice as sd

    print("Audio devices:")
    for i, dev in enumerate(sd.query_devices()):
        print(f"  [{i}] {dev['name']} ({dev['hostapi']}, "
              f"in={dev['max_input_channels']} out={dev['max_output_channels']})")
    return 0


def find_loopback_device(preferred: str = "") -> int | None:
    """Find a WASAPI loopback device on Windows. Returns device index or None."""
    import sounddevice as sd

    for i, dev in enumerate(sd.query_devices()):
        name = dev["name"].lower()
        if preferred and preferred.lower() not in name:
            continue
        # WASAPI loopback devices show up as output devices; sounddevice
        # exposes them for loopback capture on Windows.
        if dev["max_output_channels"] > 0 and "loopback" in name:
            return i
    return None


def record(output: Path, duration: float | None, device: str = "") -> int:
    import sounddevice as sd
    import numpy as np

    loopback = find_loopback_device(device)
    if loopback is None:
        print("No loopback device found. Recording microphone only.")
        print("On Windows, make sure a speaker or headset is the default output.")
        input_device = None
    else:
        print(f"Loopback device: {sd.query_devices(loopback)['name']}")
        input_device = loopback

    frames: queue.Queue = queue.Queue()
    stop = threading.Event()

    def callback(indata, _frames, _time, status):
        if status:
            print(f"Audio warning: {status}", file=sys.stderr)
        frames.put(indata.copy())

    stream_kwargs: dict = {
        "samplerate": SAMPLE_RATE,
        "channels": CHANNELS,
        "callback": callback,
        "dtype": "int16",
    }
    if input_device is not None:
        stream_kwargs["device"] = input_device

    output.parent.mkdir(parents=True, exist_ok=True)
    started = time.time()
    with sd.InputStream(**stream_kwargs):
        print(f"Recording to {output}. Press Ctrl+C to stop.")
        try:
            while not stop.is_set():
                if duration is not None and time.time() - started >= duration:
                    break
                time.sleep(0.2)
        except KeyboardInterrupt:
            print("\nStopping.")

    with wave.open(str(output), "wb") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        while not frames.empty():
            chunk = frames.get()
            wf.writeframes(chunk.tobytes())
    print(f"Saved {output}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="recordings/meeting.wav")
    parser.add_argument("--duration", type=float, default=None,
                        help="Seconds to record; omit to record until Ctrl+C")
    parser.add_argument("--device", default="", help="Preferred device name")
    parser.add_argument("--list-devices", action="store_true")
    args = parser.parse_args(argv)
    if args.list_devices:
        return list_devices()
    return record(Path(args.out), args.duration, args.device)


if __name__ == "__main__":
    sys.exit(main())
