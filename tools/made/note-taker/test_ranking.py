"""Prove the skip-the-rest rule on a fake transcript.

5 fake chunks go in. Only the 2 with decisions or action items may come
out. Run it with:  python test_ranking.py
or through the transcriber:  python transcribe.py --test-ranking
"""

from __future__ import annotations

from transcribe import rank_segments

# Fake transcript: 5 chunks. Chunk 2 has a decision, chunk 4 has an action
# item. Chunks 1, 3, 5 are small talk / status with no decision.
FAKE_SEGMENTS = [
    {"start": 0, "end": 30,
     "text": "Hey everyone, good morning, how was your weekend, mine was fine, "
             "the weather was nice, did anyone watch the game last night."},
    {"start": 30, "end": 60,
     "text": "Okay so we decided to go with the blue design for the launch page, "
             "everyone agreed, that is the decision."},
    {"start": 60, "end": 90,
     "text": "Just a quick status update, nothing changed since last week, "
             "the dashboard is still loading fine, no new bugs to report."},
    {"start": 90, "end": 120,
     "text": "Action item, Priya will send the updated numbers by Friday, "
             "she is the owner for that, deadline is Friday."},
    {"start": 120, "end": 150,
     "text": "Alright, thanks everyone, same time next week, have a good day, "
             "see you all then."},
]


def run_test() -> int:
    kept = rank_segments(FAKE_SEGMENTS, keep_score=3)
    print(f"Input:  {len(FAKE_SEGMENTS)} chunks")
    print(f"Output: {len(kept)} chunks")
    for k in kept:
        print(f"  kept [{k['start']:.0f}s] score={k['score']} reasons={k['reasons']}")
        print(f"    {k['text'][:100]}")
    expected_starts = {30, 90}
    actual_starts = {k["start"] for k in kept}
    if actual_starts == expected_starts:
        print("PASS: only the decision chunk and the action-item chunk came out.")
        return 0
    print(f"FAIL: expected chunks starting at {expected_starts}, got {actual_starts}")
    return 1


if __name__ == "__main__":
    raise SystemExit(run_test())
