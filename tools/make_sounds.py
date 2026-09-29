#!/usr/bin/env python3
"""Synthesizes the game's original sound effects into audio/*.wav.

Placeholder-quality but original: a glass marble clicking into a wooden hole,
and a heavier thud for kills. Re-run to regenerate: python3 tools/make_sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100


def write(name: str, samples: list[float]) -> None:
    peak = max(abs(s) for s in samples) or 1.0
    frames = b"".join(struct.pack("<h", int(32000 * s / peak)) for s in samples)
    path = Path(__file__).resolve().parent.parent / "audio" / name
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)


def tone(freq: float, decay: float, t: float) -> float:
    return math.sin(2 * math.pi * freq * t) * math.exp(-t / decay)


def click() -> list[float]:
    """Glass on hardwood: bright, very short partials over a soft knock."""
    rng = random.Random(7)
    out = []
    for n in range(int(RATE * 0.07)):
        t = n / RATE
        glass = 0.55 * tone(2350, 0.006, t) + 0.35 * tone(3920, 0.004, t) + 0.2 * tone(6100, 0.0025, t)
        wood = 0.5 * tone(420, 0.012, t) + 0.25 * tone(880, 0.008, t)
        tick = (rng.random() * 2 - 1) * math.exp(-t / 0.0008) * 0.6
        out.append(glass + wood + tick)
    return out


def thud() -> list[float]:
    """A kill: a low knock plus a crack, with a little pitch drop."""
    rng = random.Random(11)
    out = []
    for n in range(int(RATE * 0.35)):
        t = n / RATE
        drop = 140 * math.exp(-t / 0.08) + 70
        body = math.sin(2 * math.pi * drop * t) * math.exp(-t / 0.09)
        crack = (rng.random() * 2 - 1) * math.exp(-t / 0.01) * 0.8
        ring = 0.3 * tone(1650, 0.03, t)
        out.append(body + crack + ring)
    return out


write("marble_click.wav", click())
write("kill_thud.wav", thud())
print("wrote audio/marble_click.wav and audio/kill_thud.wav")
