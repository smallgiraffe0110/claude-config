#!/usr/bin/env python3
"""Generate a short, loud submit blip for Claude Code hooks.

A bright two-partial pluck with a fast decay — pleasant enough to hear
on every prompt submit, mastered to -1 dBFS so it cuts through where
the quietly-mastered system Pop does not. Output: sounds/submit-blip.wav
"""
import math
import os
import struct
import wave

SR = 44100
DUR = 0.18
OUT = os.path.expanduser("~/.claude/hooks/sounds/submit-blip.wav")

samples = []
for n in range(int(DUR * SR)):
    t = n / SR
    env = math.exp(-t * 28)
    s = 0.7 * math.sin(2 * math.pi * 880 * t)
    s += 0.35 * math.sin(2 * math.pi * 1760 * t)
    s += 0.15 * math.sin(2 * math.pi * 2640 * t) * math.exp(-t * 60)
    samples.append(s * env)

peak = max(abs(s) for s in samples)
gain = 0.89 / peak  # ~-1 dBFS

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with wave.open(OUT, "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767))
        for s in samples))

print(f"wrote {OUT}: {DUR}s at -1 dBFS")
