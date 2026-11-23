# 효과음 합성(저작권 걱정 없는 직접 생성). 실행: python3 gen_sfx.py
import numpy as np, wave
R = 22050
def sine(f, d, vol=0.5, dec=6.0):
    t = np.arange(int(R * d)) / R
    return np.sin(2 * np.pi * f * t) * np.exp(-dec * t) * vol
def sq(f, d, vol=0.3, dec=8.0):
    t = np.arange(int(R * d)) / R
    return np.sign(np.sin(2 * np.pi * f * t)) * np.exp(-dec * t) * vol
def noise(d, vol=0.3, dec=20.0):
    t = np.arange(int(R * d)) / R
    return (np.random.RandomState(1).rand(len(t)) * 2 - 1) * np.exp(-dec * t) * vol
def sweep(f0, f1, d, vol=0.3):
    t = np.arange(int(R * d)) / R
    f = f0 + (f1 - f0) * t / d
    return np.sin(2 * np.pi * np.cumsum(f) / R) * vol * np.minimum(1, (d - t) * 8) * np.minimum(1, t * 40)
def seq(parts, total):
    out = np.zeros(int(R * total))
    for t0, w in parts:
        i = int(R * t0); e = min(len(out), i + len(w)); out[i:e] += w[:e - i]
    return out
def save(name, w):
    w = np.clip(w, -1, 1)
    with wave.open('assets/sfx/%s.wav' % name, 'w') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(R)
        f.writeframes((w * 32000).astype('<i2').tobytes())
NOTE = lambda n: 440 * 2 ** ((n - 69) / 12)
save('lever', seq([(0, sq(90, 0.12, 0.4, 20)), (0.1, noise(0.05, 0.3))], 0.3))
save('spin', seq([(i * 0.07, sq(500 + i * 25, 0.03, 0.2, 40)) for i in range(14)], 1.1))
save('reel_stop', seq([(0, sine(110, 0.15, 0.7, 25)), (0, noise(0.04, 0.3))], 0.2))
# 등급별 당첨음: 등급이 높을수록 음이 많고 길고 높다
for g in range(7):
    notes = [72, 76, 79, 84, 88, 91, 96][:2 + g]
    parts = [(i * 0.08, sine(NOTE(n), 0.5, 0.35, 5) + np.pad(sine(NOTE(n) * 2, 0.3, 0.12, 8), (0, len(sine(1, 0.5)) - len(sine(1, 0.3))))) for i, n in enumerate(notes)]
    if g >= 4: parts.append((0, sweep(200, 1200, 0.5, 0.25)))
    if g >= 5: parts.append((0, sine(60, 0.8, 0.8, 4)))
    if g >= 6: parts.append((0.5, sweep(300, 2400, 0.9, 0.3)))
    save('win_%d' % g, seq(parts, 0.9 + 0.2 * g))
J = [(i * 0.11, sine(NOTE(n), 0.6, 0.35, 4) + np.pad(sq(NOTE(n) * 2, 0.15, 0.1, 12), (0, len(sine(1, 0.6)) - len(sq(1, 0.15))))) for i, n in enumerate([72, 76, 79, 84, 79, 84, 88, 91, 96, 96])]
J += [(1.2 + i * 0.05, sine(1800 + 150 * (i % 5), 0.12, 0.2, 18)) for i in range(30)]
save('jackpot', seq(J, 3.2))
save('reveal', seq([(0, sweep(300, 1500, 0.7, 0.3)), (0.7, sine(NOTE(84), 0.8, 0.5, 3)), (0.7, sine(NOTE(91), 0.8, 0.35, 3)), (0.7, sine(NOTE(96), 0.8, 0.3, 3))], 1.6))
print('ok')
