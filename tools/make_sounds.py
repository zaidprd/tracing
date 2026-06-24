#!/usr/bin/env python3
"""Generate the game's sound effects from scratch (no external assets).

Produces two short WAVs used by the game:
  - assets/audio/click.wav    : a soft UI tick
  - assets/audio/success.wav  : a cheerful little arpeggio on glyph completion

These are synthesized here, so they are original and free of any licensing
concerns. Run:  python3 tools/make_sounds.py
"""
import math
import os
import struct
import wave

SR = 44100


def _render(length_s):
    return [0.0] * int(length_s * SR)


def tone(buf, start_s, dur, freq, amp=0.5, decay=6.0, partial=0.3):
    n0 = int(start_s * SR)
    n = int(dur * SR)
    for i in range(n):
        t = i / SR
        # fast attack, exponential decay
        env = math.exp(-decay * t) * (1.0 - math.exp(-160.0 * t))
        s = math.sin(2 * math.pi * freq * t)
        s += partial * math.sin(2 * math.pi * 2 * freq * t)   # soft bell partial
        idx = n0 + i
        if 0 <= idx < len(buf):
            buf[idx] += amp * env * s


def save(buf, path):
    peak = max(1e-6, max(abs(v) for v in buf))
    norm = 0.92 / peak
    frames = bytearray()
    for v in buf:
        s = int(max(-1.0, min(1.0, v * norm)) * 32767)
        frames += struct.pack("<h", s)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print("wrote %s (%.2fs)" % (path, len(buf) / SR))


def make_click(path):
    buf = _render(0.12)
    tone(buf, 0.0, 0.10, 1150.0, amp=0.6, decay=55.0, partial=0.15)
    tone(buf, 0.0, 0.10, 620.0, amp=0.35, decay=60.0, partial=0.0)
    save(buf, path)


def make_success(path):
    buf = _render(0.95)
    # Happy ascending major arpeggio: C5 E5 G5 C6
    notes = [523.25, 659.25, 783.99, 1046.50]
    for i, f in enumerate(notes):
        tone(buf, 0.085 * i, 0.55, f, amp=0.5, decay=5.0, partial=0.35)
    # a little sparkle to finish
    tone(buf, 0.34, 0.45, 1318.51, amp=0.32, decay=6.0, partial=0.4)
    save(buf, path)


def main():
    out = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets", "audio"))
    os.makedirs(out, exist_ok=True)
    make_click(os.path.join(out, "click.wav"))
    make_success(os.path.join(out, "success.wav"))


if __name__ == "__main__":
    main()
