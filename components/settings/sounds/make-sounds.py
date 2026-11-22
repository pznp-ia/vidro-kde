#!/usr/bin/env python3
"""Vidro sound theme generator — minimalist, Mac-like UI sounds made by synthesis (no samples, no licenses).
Login/logout: a "startup" piece in the spirit of mid-90s desktop startups (rising whoosh, sparkling
arpeggio, blooming chord) — an original composition.

Usage: python3 -I make-sounds.py <theme-folder>
Writes <folder>/index.theme and <folder>/stereo/<event>.oga (freedesktop sound names).

Timbre: a struck glass — inharmonic partials (1, 2.32, 4.25, 6.63 × f) with fast decay on the high
ones, 4 ms attack, a slight detune between left and right (shimmer) and a small room (feedback delays).
Each event is a short motif in C major pentatonic, so everything sounds like one family."""
import array, math, os, random, subprocess, sys, tempfile, wave

RATE = 48000
OUT = sys.argv[1] if len(sys.argv) > 1 else 'vidro'
VERSION = '5'

NOTE = {}
for octave in range(1, 9):
    for i, n in enumerate(['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']):
        NOTE[f'{n}{octave}'] = 440.0 * 2 ** ((i - 9) / 12 + (octave - 4))
        flat = {'C#': 'Db', 'D#': 'Eb', 'F#': 'Gb', 'G#': 'Ab', 'A#': 'Bb'}.get(n)
        if flat:
            NOTE[f'{flat}{octave}'] = NOTE[f'{n}{octave}']

PARTIALS = ((1.0, 1.0, 1.0), (2.32, 0.42, 1.9), (4.25, 0.20, 3.2), (6.63, 0.09, 5.0))   # ratio, gain, decay speed


def glass(freq, dur=0.9, gain=0.5, decay=4.0, bright=1.0):
    """One glass strike → (left, right) float lists."""
    n = int(RATE * dur)
    left, right = [0.0] * n, [0.0] * n
    attack = int(RATE * 0.004)
    for ratio, g, dspeed in PARTIALS:
        g *= bright ** (ratio > 1)
        f = freq * ratio
        if f > RATE / 2.2:
            continue
        wl, wr = 2 * math.pi * f / RATE, 2 * math.pi * f * 1.0015 / RATE   # tiny detune = shimmer
        k = decay * dspeed / RATE
        for i in range(n):
            env = math.exp(-k * i) * (i / attack if i < attack else 1.0)
            left[i] += gain * g * env * math.sin(wl * i)
            right[i] += gain * g * env * math.sin(wr * i + 0.3)
    return left, right


def noise(dur, gain=0.2, decay=30.0, smooth=0.6, seed=1):
    """Soft filtered noise burst (shutter, crumbling)."""
    rnd = random.Random(seed)
    n = int(RATE * dur)
    l, r, yl, yr = [0.0] * n, [0.0] * n, 0.0, 0.0
    for i in range(n):
        env = math.exp(-decay * i / RATE)
        yl = smooth * yl + (1 - smooth) * rnd.uniform(-1, 1)
        yr = smooth * yr + (1 - smooth) * rnd.uniform(-1, 1)
        l[i], r[i] = gain * env * yl, gain * env * yr
    return l, r


def mix(parts, total):
    """parts: [(start_seconds, (left, right))] → stereo buffers of `total` seconds."""
    n = int(RATE * total)
    L, R = [0.0] * n, [0.0] * n
    for start, (l, r) in parts:
        o = int(RATE * start)
        for i in range(min(len(l), n - o)):
            L[o + i] += l[i]
            R[o + i] += r[i]
    return L, R


def room(L, R, wet=0.18):
    """Small room: a few feedback delays, crossed between channels."""
    for d, g in ((0.031, 0.5), (0.047, 0.42), (0.071, 0.33)):
        k = int(RATE * d)
        for i in range(k, len(L)):
            L[i] += wet * g * R[i - k]
            R[i] += wet * g * L[i - k]
    return L, R


def pad(notes, dur, attack=1.2, release=2.0, cut0=500.0, cut1=2600.0, gain=0.22, detune=0.006, seed=3):
    """Warm analog-style pad: 3 detuned saws per note through a low-pass that opens over time (swell)."""
    rnd = random.Random(seed)
    n = int(RATE * dur)
    L, R = [0.0] * n, [0.0] * n
    for note in notes:
        f0 = NOTE[note] if isinstance(note, str) else note
        for k, dt in enumerate((-detune, 0.0, detune)):
            f = f0 * (1 + dt)
            ph = rnd.random()
            pan = 0.5 + (k - 1) * 0.35          # spread the 3 voices left/centre/right
            yl = yr = 0.0
            inc = f / RATE
            for i in range(n):
                t = i / RATE
                ph += inc
                if ph >= 1.0:
                    ph -= 1.0
                saw = 2 * ph - 1
                # envelope: slow swell, hold, long release
                env = min(1.0, t / attack) if t < attack else 1.0
                if t > dur - release:
                    env *= max(0.0, (dur - t) / release) ** 1.6
                cut = cut0 + (cut1 - cut0) * min(1.0, t / (attack * 1.8))
                a = 1 - math.exp(-2 * math.pi * cut / RATE)
                yl += a * (saw - yl)
                yr += a * (yl - yr)            # 2-pole
                v = gain * env * yr
                L[i] += v * (1 - pan)
                R[i] += v * pan
    return L, R


def hall(L, R, wet=0.35, size=1.0):
    """Lush reverb (Schroeder: 4 comb + 2 all-pass per channel, different lengths left/right)."""
    def channel(x, combs, aps):
        out = [0.0] * len(x)
        for d, g in combs:
            d = int(d * size)
            buf, idx, lp = [0.0] * d, 0, 0.0
            for i, v in enumerate(x):
                y = buf[idx]
                lp = 0.7 * y + 0.3 * lp           # damping: darker tail
                buf[idx] = v + g * lp
                idx = (idx + 1) % d
                out[i] += y * 0.25
        for d, g in aps:
            buf, idx = [0.0] * d, 0
            for i, v in enumerate(out):
                b = buf[idx]
                y = -v + b
                buf[idx] = v + g * b
                idx = (idx + 1) % d
                out[i] = y
        return out
    wl = channel(L, ((1557, 0.84), (1617, 0.83), (1491, 0.85), (1422, 0.86)), ((225, 0.5), (556, 0.5)))
    wr = channel(R, ((1580, 0.84), (1640, 0.83), (1514, 0.85), (1445, 0.86)), ((248, 0.5), (579, 0.5)))
    return [a * (1 - wet) + b * wet * 2.2 for a, b in zip(L, wl)], [a * (1 - wet) + b * wet * 2.2 for a, b in zip(R, wr)]


def tone(freq, dur=0.5, kind='soft', gain=0.5):
    """Minimal UI timbres:
    soft  – clean sine with a hint of 2nd harmonic (ping)
    pop   – sine with a fast downward pitch blip (bubble pop)
    tink  – small marimba: sine + 3.9x partial that dies fast
    basso – low muted thud (errors)
    purr  – soft tone with tremolo (warnings)"""
    n = int(RATE * dur)
    L, R = [0.0] * n, [0.0] * n
    ph = ph2 = 0.0
    for i in range(n):
        t = i / RATE
        f = freq
        if kind == 'pop':
            f = freq * (1 + 0.9 * math.exp(-t * 180))
        elif kind == 'basso':
            f = freq * (1 + 0.5 * math.exp(-t * 40))
        ph += 2 * math.pi * f / RATE
        ph2 += 2 * math.pi * f * (3.9 if kind == 'tink' else 2.0) / RATE
        att = min(1.0, t / (0.0015 if kind in ('pop', 'tink') else 0.004))
        if kind == 'pop':
            v = math.sin(ph) * math.exp(-t * 28)
        elif kind == 'tink':
            v = math.sin(ph) * math.exp(-t * 14) + 0.45 * math.sin(ph2) * math.exp(-t * 60)
        elif kind == 'basso':   # muted "dum": fundamental + strong 2nd/3rd harmonics (audible on laptop speakers)
            v = (math.sin(ph) + 0.8 * math.sin(ph2) + 0.45 * math.sin(1.5 * ph2)) * math.exp(-t * 11) * 0.6
        elif kind == 'purr':
            v = (math.sin(ph) + 0.15 * math.sin(ph2)) * math.exp(-t * 6) * (0.75 + 0.25 * math.sin(2 * math.pi * 22 * t))
        else:
            v = (math.sin(ph) + 0.12 * math.sin(ph2)) * math.exp(-t * 7)
        v *= gain * att
        L[i], R[i] = v, v
    return L, R


LOWER = 0.5   # UI sounds are written an octave up and played an octave lower (warmer, less shrill)


def seq(items, total, wet=0.12, transpose=LOWER):
    """items: [(start, freq_or_note, dur, kind, gain)] → small soft room."""
    parts = [(t, tone((NOTE[n] if isinstance(n, str) else n) * transpose, d, k, g)) for t, n, d, k, g in items]
    return room(*mix(parts, total), wet)


def whoosh(dur, f0=180.0, f1=3200.0, gain=0.25, rise=True, seed=5):
    """Filtered noise sweeping up (or down): the rushing swell under the startup sound."""
    rnd = random.Random(seed)
    n = int(RATE * dur)
    L, R = [0.0] * n, [0.0] * n
    lowl = bandl = lowr = bandr = 0.0
    for i in range(n):
        x = i / n
        f = f0 * (f1 / f0) ** (x if rise else 1 - x)
        fc = 2 * math.sin(math.pi * min(f, RATE / 6) / RATE)
        env = (math.sin(math.pi * x) ** 1.5) if rise else (1 - x) ** 2
        for side in (0, 1):
            w = rnd.uniform(-1, 1)
            if side == 0:
                lowl += fc * bandl; high = w - lowl - 0.5 * bandl; bandl += fc * high; L[i] = gain * env * bandl
            else:
                lowr += fc * bandr; high = w - lowr - 0.5 * bandr; bandr += fc * high; R[i] = gain * env * bandr
    return L, R


def bell(freq, dur=3.0, gain=0.2, decay=1.4):
    """Soft sine bell with slow chorus (two slightly detuned sines) — the shimmering voice."""
    n = int(RATE * dur)
    L, R = [0.0] * n, [0.0] * n
    for i in range(n):
        t = i / RATE
        env = math.exp(-decay * t) * min(1.0, t / 0.006)
        a = 2 * math.pi * freq * t
        L[i] = gain * env * (math.sin(a) + 0.5 * math.sin(a * 1.004) + 0.08 * math.sin(2 * a))
        R[i] = gain * env * (math.sin(a * 1.002) + 0.5 * math.sin(a * 0.997) + 0.08 * math.sin(2 * a))
    return L, R


def startup():
    """Login (serious): a slow, low whoosh; an open-fifth chord (D–A–E, neither happy nor sad) swells in;
    three deep, unhurried bells; the chord settles in a large hall."""
    total = 6.4
    parts = [(0.0, whoosh(2.6, 90, 1400, 0.20)),
             (0.2, pad(['D3', 'A3', 'E4', 'A4'], 5.8, attack=1.8, release=3.0, cut0=300, cut1=1300, gain=0.12)),
             (0.6, pad(['D2'], 5.2, attack=1.6, release=2.8, cut0=160, cut1=320, gain=0.10, detune=0.002))]
    for t, n, g in ((0.9, 'A3', 0.13), (1.45, 'E4', 0.12), (2.0, 'A4', 0.11)):
        parts.append((t, bell(NOTE[n], 3.6, g, 1.1)))
    for n, g in (('D4', 0.10), ('A4', 0.08), ('E5', 0.04)):   # quiet bloom of the chord
        parts.append((2.0, bell(NOTE[n], 4.2, g, 0.8)))
    return hall(*mix(parts, total), wet=0.45, size=1.25)


def shutdown():
    """Logout (serious): the same open chord closes and sinks; two deep bells falling."""
    total = 4.8
    parts = [(0.0, pad(['D3', 'A3', 'E4'], 4.0, attack=0.4, release=3.2, cut0=1200, cut1=280, gain=0.12)),
             (0.0, whoosh(2.4, 1200, 80, 0.13, rise=False)),
             (0.3, pad(['D2'], 3.8, attack=0.5, release=3.0, cut0=170, cut1=120, gain=0.10, detune=0.002))]
    for t, n, g in ((0.15, 'A4', 0.11), (0.75, 'E4', 0.11), (1.35, 'A3', 0.12)):
        parts.append((t, bell(NOTE[n], 3.2, g, 1.3)))
    return hall(*mix(parts, total), wet=0.42, size=1.15)


def motif(notes, step=0.11, dur=0.9, gain=0.45, decay=4.0, bright=1.0, tail=0.5):
    parts = [(i * step, glass(NOTE[n] if isinstance(n, str) else n, dur, gain, decay, bright)) for i, n in enumerate(notes)]
    return room(*mix(parts, step * (len(notes) - 1) + dur + tail))


def write(name, L, R):
    peak = max(1e-9, max(max(abs(x) for x in L), max(abs(x) for x in R)))
    scale = 0.6 / peak * 32767   # ≈ Ocean loudness
    fade = int(RATE * 0.02)
    n = len(L)
    data = array.array('h')
    for i in range(n):
        f = min(1.0, (n - i) / fade)
        data.append(int(max(-32767, min(32767, L[i] * scale * f))))
        data.append(int(max(-32767, min(32767, R[i] * scale * f))))
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as t:
        tmp = t.name
    with wave.open(tmp, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(data.tobytes())
    dest = os.path.join(OUT, 'stereo', name + '.oga')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp, '-c:a', 'libvorbis', '-q:a', '5', '-f', 'ogg', dest], check=True)
    os.remove(tmp)


def serious_error():
    """Error: one short, firm "tum" — two muted tones a tritone apart, sounding together, with a knock."""
    parts = [(0, tone(NOTE['E3'], 0.4, 'basso', 0.8)), (0, tone(NOTE['A#3'], 0.4, 'basso', 0.55)),
             (0, noise(0.03, 0.4, 150, 0.55, 21))]
    return room(*mix(parts, 0.5), 0.07)


def serious_failure():
    """Failure: two muted notes falling a minor third, slow and low."""
    parts = [(0, tone(NOTE['D4'], 0.5, 'basso', 0.75)), (0, noise(0.03, 0.3, 150, 0.55, 31)),
             (0.24, tone(NOTE['B3'], 0.7, 'basso', 0.8)), (0.24, noise(0.03, 0.3, 150, 0.55, 32))]
    return room(*mix(parts, 1.0), 0.09)


def error_sound(notes, gap=0.16):
    """Error: muted "dum" (harmonic-rich, ~200 Hz) with a soft knock on top so it cuts through small speakers."""
    parts = []
    for i, n in enumerate(notes):
        parts.append((i * gap, tone(NOTE[n], 0.45, 'basso', 0.9)))
        parts.append((i * gap, noise(0.03, 0.35, 140, 0.55, 11 + i)))
    return room(*mix(parts, gap * (len(notes) - 1) + 0.55), 0.08)


def sounds():
    s = {}
    s['desktop-login'] = s['theme-demo'] = startup()
    s['desktop-logout'] = shutdown()
    s['service-login'] = seq([(0, 'G5', 0.4, 'soft', 0.4), (0.09, 'D6', 0.6, 'soft', 0.4)], 0.8)
    s['service-logout'] = seq([(0, 'D6', 0.4, 'soft', 0.4), (0.09, 'G5', 0.6, 'soft', 0.4)], 0.8)
    s['dialog-information'] = seq([(0, 'E6', 0.6, 'soft', 0.5)], 0.7)
    s['dialog-question'] = seq([(0, 'G5', 0.35, 'tink', 0.45), (0.11, 'D6', 0.5, 'tink', 0.45)], 0.7)
    s['dialog-warning'] = s['dialog-warning-auth'] = seq([(0, 'A4', 0.45, 'purr', 0.55), (0.17, 'A4', 0.55, 'purr', 0.5)], 0.8)
    s['dialog-error'] = serious_error()
    s['dialog-error-serious'] = s['dialog-error-critical'] = error_sound(['G3', 'D3'])
    s['message-new-instant'] = seq([(0, 'C6', 0.2, 'pop', 0.6), (0.09, 'G6', 0.25, 'pop', 0.55)], 0.4)
    s['message-new-email'] = seq([(0, 'E6', 0.3, 'tink', 0.4), (0.08, 'G6', 0.3, 'tink', 0.4), (0.16, 'C7', 0.45, 'tink', 0.4)], 0.65)
    s['message-attention'] = s['message-highlight'] = s['window-attention'] = seq([(0, 'D6', 0.3, 'tink', 0.45), (0.2, 'D6', 0.4, 'tink', 0.45)], 0.65)
    s['message-sent-instant'] = seq([(0, 'G6', 0.18, 'pop', 0.45)], 0.25)
    s['message-contact-in'] = seq([(0, 'C6', 0.2, 'pop', 0.4), (0.07, 'E6', 0.25, 'pop', 0.4)], 0.35)
    s['message-contact-out'] = seq([(0, 'E6', 0.2, 'pop', 0.4), (0.07, 'C6', 0.25, 'pop', 0.4)], 0.35)
    s['complete'] = s['completion-success'] = s['outcome-success'] = s['complete-media-burn'] = \
        seq([(0, 'C6', 0.4, 'tink', 0.45), (0.09, 'G6', 0.6, 'tink', 0.45)], 0.8)
    s['completion-partial'] = seq([(0, 'C6', 0.4, 'tink', 0.45), (0.09, 'E6', 0.5, 'tink', 0.4)], 0.7)
    s['completion-fail'] = s['outcome-failure'] = s['complete-media-error'] = serious_failure()
    s['device-added'] = seq([(0, 'C6', 0.15, 'pop', 0.5), (0.07, 'G6', 0.25, 'pop', 0.5)], 0.35)
    s['device-removed'] = seq([(0, 'G6', 0.15, 'pop', 0.5), (0.07, 'C6', 0.25, 'pop', 0.5)], 0.35)
    s['power-plug'] = seq([(0, 'F6', 0.9, 'soft', 0.5)], 1.0)                # single clean charging chime
    s['power-unplug'] = seq([(0, 'C6', 0.6, 'soft', 0.4)], 0.7)
    s['battery-low'] = s['battery-caution'] = seq([(0, 'E4', 0.5, 'purr', 0.6), (0.22, 'C4', 0.6, 'purr', 0.6)], 0.9)
    s['battery-full'] = seq([(0, 'F6', 0.6, 'soft', 0.45), (0.1, 'C7', 0.8, 'soft', 0.4)], 1.0)
    s['audio-volume-change'] = seq([(0, 'A5', 0.09, 'pop', 0.5)], 0.11, 0.04)
    s['bell'] = s['bell-window-system'] = seq([(0, 'A6', 0.25, 'tink', 0.45)], 0.3)
    s['button-pressed'] = s['button-pressed-modifier'] = seq([(0, 'E6', 0.05, 'pop', 0.35)], 0.07, 0.0)
    s['completion-rotation'] = seq([(0, 'E6', 0.12, 'tink', 0.3)], 0.15)
    # shutter: two soft clicks
    L, R = mix([(0, noise(0.035, 0.5, 120, 0.35, 2)), (0.06, noise(0.05, 0.4, 90, 0.45, 3))], 0.14)
    s['screen-capture'] = room(L, R, 0.06)
    # trash: crumpled paper — many tiny filtered noise crackles
    rnd = random.Random(7)
    parts = [(rnd.uniform(0, 0.38), noise(rnd.uniform(0.01, 0.04), rnd.uniform(0.15, 0.4), rnd.uniform(60, 160), rnd.uniform(0.2, 0.6), i)) for i in range(26)]
    s['trash-empty'] = room(*mix(parts, 0.5), 0.06)
    s['alarm-clock-elapsed'] = seq([(i * 0.12 + (i // 3) * 0.35, n, 0.4, 'tink', 0.45)
                                    for i, n in enumerate(['E6', 'G6', 'C7'] * 3)], 2.2)
    s['phone-incoming-call'] = seq([(i * 0.16, n, 0.4, 'soft', 0.45) for i, n in enumerate(['E6', 'G6', 'E6', 'G6'])], 1.1)
    s['media-insert-request'] = s['dialog-question']
    s['game-over-winner'] = seq([(i * 0.1, n, 0.6, 'tink', 0.45) for i, n in enumerate(['C6', 'E6', 'G6', 'C7'])], 1.1)
    s['game-over-loser'] = error_sound(['G4', 'E4', 'C4'], gap=0.16)
    return s


def main():
    os.makedirs(os.path.join(OUT, 'stereo'), exist_ok=True)
    done = {}
    for name, (L, R) in sounds().items():
        key = id(L)
        if key in done:   # same sound under two names → link
            p = os.path.join(OUT, 'stereo', name + '.oga')
            if os.path.lexists(p):
                os.remove(p)
            os.symlink(done[key] + '.oga', p)
            continue
        write(name, L, R)
        done[key] = name
    with open(os.path.join(OUT, 'index.theme'), 'w') as f:
        f.write('[Sound Theme]\nName=Vidro\nComment=Sons minimalistas do tema Vidro (gerados por síntese)\n'
                'Inherits=ocean,freedesktop\nDirectories=stereo\n\n[stereo]\nOutputProfile=stereo\n')
    open(os.path.join(OUT, '.vidro-version'), 'w').write(VERSION)
    print('ok', len(done), 'sounds')


if __name__ == '__main__':
    main()
