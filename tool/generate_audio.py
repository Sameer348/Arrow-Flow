"""Synthesizes the game's original sound effects and ambient music loop.

Everything is generated from sine/noise primitives, so there are no
third-party audio licenses. Run:  python3 tool/generate_audio.py
"""
import math, random, struct, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets')


def write(path, samples, sr=SR):
    path = os.path.join(OUT, path)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        peak = max(1e-6, max(abs(s) for s in samples))
        scale = min(1.0, 0.89 / peak)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


def env(t, a, d):
    """Attack/exponential-decay envelope."""
    if t < a:
        return t / a
    return math.exp(-(t - a) / d)


def tone(dur, f0, f1=None, a=0.004, d=0.08, harm=(1.0, 0.3, 0.1), vib=0.0):
    f1 = f0 if f1 is None else f1
    n = int(dur * SR)
    out, ph = [], 0.0
    for i in range(n):
        t = i / SR
        k = t / dur
        f = f0 * (f1 / f0) ** k
        f *= 1 + vib * math.sin(2 * math.pi * 6 * t)
        ph += 2 * math.pi * f / SR
        s = sum(h * math.sin(ph * (j + 1)) for j, h in enumerate(harm))
        out.append(s * env(t, a, d))
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0] * len(tracks)
    n = max(int(o * SR) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * n
    for t, o in zip(tracks, offsets):
        s = int(o * SR)
        for i, v in enumerate(t):
            out[s + i] += v
    return out


def noise(dur, a=0.002, d=0.05, lp=0.2, seed=1):
    rnd = random.Random(seed)
    n = int(dur * SR)
    out, y = [], 0.0
    for i in range(n):
        t = i / SR
        y += lp * (rnd.uniform(-1, 1) - y)
        out.append(y * env(t, a, d))
    return out


def whoosh(dur=0.32):
    rnd = random.Random(7)
    n = int(dur * SR)
    out, y = [], 0.0
    for i in range(n):
        t = i / SR
        k = t / dur
        lp = 0.02 + 0.5 * k  # filter opens = rising whoosh
        y += lp * (rnd.uniform(-1, 1) - y)
        e = math.sin(math.pi * min(1, k * 1.25)) ** 1.5
        out.append(y * e)
    return out


def scale_track(t, g):
    return [v * g for v in t]


# --- Sound effects ---------------------------------------------------------
write('sounds/button.wav', tone(0.07, 1250, 1050, d=0.02, harm=(1, 0.15)))
write('sounds/tap.wav', tone(0.06, 900, 700, d=0.018, harm=(1, 0.2)))
write('sounds/escape.wav', mix(scale_track(whoosh(0.34), 1.3), tone(0.22, 520, 1560, d=0.08, harm=(1, 0.25, 0.08)), offsets=[0, 0.02]))
write('sounds/blocked.wav', mix(tone(0.16, 190, 140, d=0.05, harm=(1, 0.5, 0.2)), scale_track(noise(0.08, d=0.02, lp=0.08), 0.5)))
write('sounds/combo_1.wav', mix(tone(0.25, 880, d=0.12), tone(0.25, 1320, d=0.1), offsets=[0, 0.06]))
write('sounds/combo_2.wav', mix(tone(0.3, 988, d=0.12), tone(0.3, 1319, d=0.12), tone(0.3, 1976, d=0.1), offsets=[0, 0.05, 0.1]))
write('sounds/combo_3.wav', mix(tone(0.35, 1047, d=0.14), tone(0.35, 1568, d=0.14), tone(0.35, 2093, d=0.14), tone(0.4, 2637, d=0.16, vib=0.004), offsets=[0, 0.05, 0.1, 0.15]))
write('sounds/booster.wav', mix(tone(0.4, 300, 1200, d=0.15, harm=(1, 0.4, 0.2), vib=0.01), scale_track(whoosh(0.3), 0.6)))
write('sounds/coin.wav', mix(tone(0.12, 1568, d=0.05), tone(0.3, 2093, d=0.12), offsets=[0, 0.07]))
write('sounds/star.wav', mix(tone(0.5, 1760, d=0.2, harm=(1, 0.2, 0.05), vib=0.003), scale_track(noise(0.3, d=0.1, lp=0.6, seed=3), 0.15)))
write('sounds/level_complete.wav', mix(*[tone(0.7, f, d=0.28, harm=(1, 0.3, 0.1)) for f in (523.25, 659.25, 783.99, 1046.5)],
                                       tone(1.1, 1318.5, d=0.5, vib=0.004), offsets=[0, 0.09, 0.18, 0.27, 0.36]))
write('sounds/game_over.wav', mix(*[tone(0.6, f, d=0.25, harm=(1, 0.25)) for f in (523.25, 466.16, 392.0)], offsets=[0, 0.16, 0.32]))
write('sounds/unlock.wav', mix(*[tone(0.6, f, d=0.25) for f in (783.99, 987.77, 1174.66, 1567.98)], offsets=[0, 0.07, 0.14, 0.21]))

# --- Ambient music loop (seamless, 16 s, 22.05 kHz to keep it small) -------
MSR = 22050
bars = [(220.0, 261.63, 329.63), (174.61, 220.0, 261.63), (196.0, 246.94, 293.66), (164.81, 207.65, 246.94)]
dur = 16.0
n = int(dur * MSR)
music = [0.0] * n
for bi, chord in enumerate(bars):
    start = bi * 4.0
    for f in chord:
        for i in range(int(4.6 * MSR)):
            idx = (int(start * MSR) + i) % n  # wrap = seamless loop
            t = i / MSR
            a = min(1, t / 1.2) * max(0, min(1, (4.6 - t) / 1.4))
            music[idx] += 0.12 * a * (math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2.003 * t))
# soft arpeggio sparkles
rnd = random.Random(11)
for step in range(32):
    chord = bars[(step // 8) % 4]
    f = chord[rnd.randrange(3)] * 4
    st = int(step * 0.5 * MSR)
    for i in range(int(0.9 * MSR)):
        t = i / MSR
        music[(st + i) % n] += 0.035 * math.exp(-t / 0.25) * math.sin(2 * math.pi * f * t)
write('music/ambient_loop.wav', music, sr=MSR)
print('ok')
