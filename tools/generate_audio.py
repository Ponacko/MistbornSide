#!/usr/bin/env python3
"""Synthesizes the placeholder sound set into audio/ as 16-bit mono WAVs.

Loops (ambience, hum, heartbeat, music) are built so every partial completes
a whole number of cycles over the loop and every event fits inside it, so
they loop without a click. Re-run after editing: python3 tools/generate_audio.py
"""
import wave, struct, os
import numpy as np

SR = 22050
rng = np.random.default_rng(7)
ROOT = os.path.join(os.path.dirname(__file__), "..", "audio")


def write(rel, data):
    data = np.clip(data, -1.0, 1.0)
    path = os.path.join(ROOT, rel)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((data * 32000).astype("<i2").tobytes())


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack, release):
    e = np.ones(n)
    a = max(int(SR * attack), 1)
    r = max(int(SR * release), 1)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def lowpass(x, k):
    y = np.copy(x)
    for i in range(1, len(y)):
        y[i] = y[i - 1] + k * (x[i] - y[i - 1])
    return y


def circ_lowpass(x, k):
    """Low-pass that wraps around, so the result loops seamlessly."""
    y = lowpass(np.concatenate([x[-SR:], x]), k)
    return y[SR:]


# --- one-shots -------------------------------------------------------------
def pluck():
    tt = t(0.35)
    s = np.sin(2 * np.pi * 880 * tt) * 0.6 + np.sin(2 * np.pi * 1320 * tt) * 0.25
    return s * np.exp(-tt * 14) * env(len(tt), 0.002, 0.05) * 0.5


def thump():
    tt = t(0.4)
    f = 70 * np.exp(-tt * 5) + 38
    s = np.sin(2 * np.pi * np.cumsum(f) / SR)
    click = rng.standard_normal(len(tt)) * np.exp(-tt * 120) * 0.3
    return (s * np.exp(-tt * 7) + click) * env(len(tt), 0.001, 0.08) * 0.9


def coin_ring():
    tt = t(0.8)
    s = sum(a * np.sin(2 * np.pi * f * tt) for f, a in [(2400, 0.5), (3610, 0.3), (5230, 0.15)])
    return s * np.exp(-tt * 6) * env(len(tt), 0.001, 0.1) * 0.35


def footstep():
    tt = t(0.12)
    s = lowpass(rng.standard_normal(len(tt)), 0.25) * np.exp(-tt * 40)
    return s * env(len(tt), 0.001, 0.03) * 0.6


def murmur():
    tt = t(0.9)
    carrier = lowpass(rng.standard_normal(len(tt)), 0.08)
    syll = 0.5 + 0.5 * np.sin(2 * np.pi * 5.5 * tt) * np.sin(2 * np.pi * 1.3 * tt)
    return carrier * syll * env(len(tt), 0.05, 0.2) * 1.6


def whiteout():
    tt = t(0.9)
    s = np.sin(2 * np.pi * 3200 * tt) * 0.3 + rng.standard_normal(len(tt)) * 0.2
    return s * np.exp(-tt * 3) * env(len(tt), 0.001, 0.2) * 0.5


def dagger():
    tt = t(0.18)
    sweep = np.sin(2 * np.pi * np.cumsum(1800 - 1400 * tt / 0.18) / SR)
    return (lowpass(rng.standard_normal(len(tt)), 0.5) * 0.5 + sweep * 0.2) * np.exp(-tt * 18) * 0.6


def bell():
    tt = t(3.0)
    s = sum(a * np.sin(2 * np.pi * f * tt) * np.exp(-tt * d) for f, a, d in [(440, 0.5, 1.0), (1063, 0.3, 1.6), (1630, 0.2, 2.2), (220, 0.3, 0.7)])
    return s * env(len(tt), 0.002, 0.3) * 0.6


# --- loops -----------------------------------------------------------------
def hum():
    # 2 s loop: 55 and 110 Hz complete whole cycles; 0.5 Hz beating likewise.
    tt = t(2.0)
    s = np.sin(2 * np.pi * 55 * tt) * 0.5 + np.sin(2 * np.pi * 110 * tt) * 0.3 + np.sin(2 * np.pi * 110.5 * tt) * 0.2
    return s * 0.5


def heartbeat():
    tt = t(1.0)
    out = np.zeros(len(tt))
    for start, amp in [(0.0, 1.0), (0.22, 0.7)]:
        seg = t(0.18)
        beat = np.sin(2 * np.pi * 48 * seg) * np.exp(-seg * 22) * amp
        i = int(start * SR)
        out[i:i + len(seg)] += beat
    return out * 0.8


def ambience_night():
    length = 16.0
    n = int(SR * length)
    wind = circ_lowpass(rng.standard_normal(n), 0.01) * 0.6
    out = wind
    # Drips of condensation.
    for _ in range(14):
        start = rng.uniform(0.1, length - 0.3)
        seg = t(0.09)
        f = np.linspace(1900, 700, len(seg))
        drip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-seg * 50) * rng.uniform(0.08, 0.18)
        i = int(start * SR)
        out[i:i + len(seg)] += drip
    # Distant forges: muffled clanks.
    for k in range(5):
        start = 1.0 + k * 3.1 + rng.uniform(-0.3, 0.3)
        seg = t(0.6)
        clank = (np.sin(2 * np.pi * 330 * seg) * 0.5 + lowpass(rng.standard_normal(len(seg)), 0.1)) * np.exp(-seg * 9) * 0.07
        i = int(start * SR)
        out[i:i + len(seg)] += clank
    # Ash ticking on tile.
    for _ in range(60):
        i = int(rng.uniform(0.05, length - 0.05) * SR)
        seg = t(0.006)
        out[i:i + len(seg)] += rng.standard_normal(len(seg)) * 0.02
    return out * 0.7


def music(chords, length, drone=None, bells=False, gain=0.18):
    """Pads on frequencies that are multiples of 1/length: phase-continuous loop."""
    tt = t(length)
    n = len(tt)
    out = np.zeros(n)
    seg = length / len(chords)
    for ci, chord in enumerate(chords):
        centre = (ci + 0.5) * seg
        # Raised-cosine window wrapping around the loop.
        d = np.minimum(np.abs(tt - centre), length - np.abs(tt - centre))
        w = np.clip(np.cos(np.pi * d / (seg * 1.2)) , 0, 1) ** 2
        for f in chord:
            fq = round(f * length) / length
            out += w * (np.sin(2 * np.pi * fq * tt) * 0.5 + np.sin(2 * np.pi * 2 * fq * tt) * 0.15)
    if drone:
        for f in drone:
            fq = round(f * length) / length
            out += np.sin(2 * np.pi * fq * tt) * 0.35
    if bells:
        b = bell()
        for k in range(4):
            i = int((0.5 + k * length / 4) * SR)
            j = min(i + len(b), n)
            out[i:j] += b[: j - i] * 0.5
    return out / np.max(np.abs(out)) * gain * 4


def note(name):
    names = {"A": 0, "B": 2, "C": 3, "D": 5, "E": 7, "F": 8, "G": 10}
    base, octave = name[:-1], int(name[-1])
    semis = names[base[0]] + (1 if "#" in base else 0) + (octave - 2) * 12
    return 110.0 * 2 ** (semis / 12.0)


def chord(*ns):
    return [note(n) for n in ns]


if __name__ == "__main__":
    for d in ["sfx", "ambience", "music"]:
        os.makedirs(os.path.join(ROOT, d), exist_ok=True)
    write("sfx/pluck.wav", pluck())
    write("sfx/thump.wav", thump())
    write("sfx/coin_ring.wav", coin_ring())
    write("sfx/footstep.wav", footstep())
    write("sfx/murmur.wav", murmur())
    write("sfx/whiteout.wav", whiteout())
    write("sfx/dagger.wav", dagger())
    write("sfx/bell.wav", bell())
    write("ambience/hum.wav", hum())
    write("ambience/heartbeat.wav", heartbeat())
    write("ambience/night.wav", ambience_night())
    write("music/night_city.wav", music([chord("A2", "E3", "C3"), chord("F2", "C3", "A3"), chord("C2", "G2", "E3"), chord("G2", "D3", "B3")], 16.0))
    write("music/kredik_shaw.wav", music([chord("D2", "A2", "F3"), chord("D2", "A2", "G3"), chord("D2", "A2", "F3"), chord("C2", "G2", "D#3")], 16.0, drone=[note("D2") / 2], bells=True, gain=0.16))
    print("audio written")
