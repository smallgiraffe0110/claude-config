#!/usr/bin/env python3
"""Generate the evil idle-alarm sound for Claude Code hooks.

Layers a hard-clipped tritone klaxon (Eb5/A4 detuned square waves) over a
low beating drone, then appends a whispered "Claude is waiting" rendered
by macOS `say`. Mastered to ~-0.3 dBFS so it is far louder than the
quietly-mastered system sounds. Output: sounds/evil-alarm.wav
"""
import math
import os
import struct
import subprocess
import tempfile
import wave

SR = 44100
OUT = os.path.expanduser("~/.claude/hooks/sounds/evil-alarm.wav")

def square(f, t, detune=4.0):
    a = math.sin(2 * math.pi * f * t)
    b = math.sin(2 * math.pi * (f + detune) * t)
    return (math.copysign(0.5, a) + math.copysign(0.5, b))

def saw(f, t):
    return 2.0 * ((f * t) % 1.0) - 1.0

def drone(t):
    return 0.30 * (saw(55.0, t) + saw(66.0, t)) / 2.0

samples = []

# Part 1: six alternating tritone klaxon blasts with a harsh 25 Hz tremolo.
BLAST, GAP = 0.30, 0.05
for i in range(6):
    f = 622.25 if i % 2 == 0 else 440.0  # Eb5 / A4 — the tritone
    for n in range(int(BLAST * SR)):
        t = n / SR
        env = min(1.0, n / (0.005 * SR)) * min(1.0, (BLAST * SR - n) / (0.01 * SR))
        trem = 0.75 + 0.25 * math.sin(2 * math.pi * 25 * t)
        samples.append(env * (0.9 * trem * square(f, t) + drone(len(samples) / SR)))
    samples.extend(0.9 * drone((len(samples) + n) / SR) for n in range(int(GAP * SR)))

# Part 2: a whispered "Claude is waiting." over the dying drone.
speech = []
with tempfile.TemporaryDirectory() as td:
    sp = os.path.join(td, "speech.wav")
    subprocess.run(
        ["say", "-v", "Whisper", "-r", "115", "-o", sp,
         "--file-format=WAVE", "--data-format=LEI16@44100",
         "Claude is waiting."],
        check=True,
    )
    with wave.open(sp) as w:
        raw = w.readframes(w.getnframes())
        ch = w.getnchannels()
        for n in range(0, len(raw), 2 * ch):
            speech.append(struct.unpack("<h", raw[n:n + 2])[0] / 32768.0)

peak_s = max(abs(s) for s in speech) or 1.0
samples.extend(0.15 * drone(n / SR) for n in range(int(0.15 * SR)))
base = len(samples)
for i, s in enumerate(speech):
    fade = max(0.0, 1.0 - i / len(speech))
    samples.append(0.95 * s / peak_s + 0.12 * fade * drone((base + i) / SR))

# Master: soft-clip for aggression, normalize to -0.3 dBFS.
DRIVE = 2.5
samples = [math.tanh(s * DRIVE) / math.tanh(DRIVE) for s in samples]
peak = max(abs(s) for s in samples)
gain = 0.97 / peak

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with wave.open(OUT, "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767))
        for s in samples))

print(f"wrote {OUT}: {len(samples) / SR:.2f}s, peak normalized to -0.3 dBFS")
