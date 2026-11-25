"""Synthesizes the app's sound effects as 16-bit mono WAV files (no external assets)."""
import math
import random
import struct
import sys
import wave

RATE = 44100
OUT = sys.argv[1]
random.seed(7)


def write(name, samples, gain=0.8):
    peak = max(1e-9, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * gain)) * 32767)) for s in samples)
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def mix(base, add, at):
    start = int(at * RATE)
    if len(base) < start + len(add):
        base.extend([0.0] * (start + len(add) - len(base)))
    for i, s in enumerate(add):
        base[start + i] += s
    return base


def knock(freq, length=0.05, decay=60.0, noise=0.6):
    """A short wooden knock: a damped resonance plus a noise burst."""
    out = []
    for i in range(int(RATE * length)):
        t = i / RATE
        env = math.exp(-decay * t)
        tone = math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(2 * math.pi * freq * 2.3 * t)
        out.append(env * (tone * (1 - noise) + random.uniform(-1, 1) * noise))
    return out


def bell(freq, length=0.6, decay=6.0):
    out = []
    for i in range(int(RATE * length)):
        t = i / RATE
        env = math.exp(-decay * t) * min(1.0, t * 400)
        out.append(env * (math.sin(2 * math.pi * freq * t)
                          + 0.35 * math.sin(2 * math.pi * freq * 2 * t)
                          + 0.15 * math.sin(2 * math.pi * freq * 3.01 * t)))
    return out


# Dice rattle: a cluster of knocks that thins out.
roll = silence(0.5)
t = 0.0
for k in range(11):
    mix(roll, knock(random.uniform(1500, 2600), decay=random.uniform(50, 90)), t)
    t += random.uniform(0.018, 0.05) * (1 + k * 0.12)
write("roll", roll, 0.7)

# Hold/select: one small tick.
write("hold", knock(2400, length=0.04, decay=120, noise=0.3), 0.45)

# Write a score: a soft rising pop.
pop = []
for i in range(int(RATE * 0.12)):
    t = i / RATE
    f = 620 + 500 * (t / 0.12)
    pop.append(math.exp(-35 * t) * min(1.0, t * 800) * math.sin(2 * math.pi * f * t))
write("write", pop, 0.6)

# Yamb / game over: a bright arpeggio.
chime = silence(1.0)
for n, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
    mix(chime, bell(f), n * 0.09)
write("chime", chime, 0.6)

print("ok")
