# -*- coding: utf-8 -*-
"""程序化音频生成：界面音 + 事件音 + 环境氛围（44100Hz 16bit PCM WAV）"""
import os, sys, math, wave, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from asset_common import ASSETS

SR = 44100
AUD = os.path.join(ASSETS, "audio")
os.makedirs(AUD, exist_ok=True)

def _env_exp(n, tau):
    return np.exp(-np.arange(n) / (SR * tau))

def _write(name, data, gain=1.0):
    data = np.clip(data * gain, -1.0, 1.0)
    pcm = (data * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(AUD, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm)
    print("wav:", name, round(len(data) / SR, 2), "s")

def _onopole_lp(x, cutoff):
    a = 1.0 - math.exp(-2.0 * math.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y

def gen_sfx():
    # click
    n = int(SR * 0.07)
    t = np.arange(n) / SR
    s = np.sin(2 * math.pi * 900 * t) * _env_exp(n, 0.012) * 0.5
    s += (np.random.RandomState(7).rand(n) - 0.5) * _env_exp(n, 0.004) * 0.18
    _write("click", s)
    # hover
    n = int(SR * 0.05)
    t = np.arange(n) / SR
    _write("hover", np.sin(2 * math.pi * 1350 * t) * _env_exp(n, 0.008) * 0.22)
    # chime（大调琶音，正/吉事）
    notes = [523.25, 659.25, 783.99, 1046.5]
    total = int(SR * 1.5); out = np.zeros(total)
    rs = np.random.RandomState(3)
    for k, f in enumerate(notes):
        st = int(SR * 0.14 * k)
        n = int(SR * 1.0)
        t = np.arange(min(n, total - st)) / SR
        seg = (np.sin(2 * math.pi * f * t) + 0.35 * np.sin(2 * math.pi * 2 * f * t) + 0.12 * np.sin(2 * math.pi * 3 * f * t))
        seg *= _env_exp(len(t), 0.35)
        out[st:st + len(t)] += seg * 0.3
    _write("chime", out)
    # thud（负向事件）
    n = int(SR * 0.75); t = np.arange(n) / SR
    f = 150 * np.exp(-t * 2.2) + 52
    s = np.sin(2 * math.pi * np.cumsum(f) / SR) * _env_exp(n, 0.28) * 0.75
    rs = np.random.RandomState(11)
    s += (rs.rand(n) - 0.5) * _env_exp(n, 0.03) * 0.3
    _write("thud", s)
    # build（敲击）
    total = int(SR * 0.5); out = np.zeros(total)
    rs = np.random.RandomState(5)
    for st in (0.0, 0.18):
        n = int(SR * 0.1)
        seg = (rs.rand(n) - 0.5) * _env_exp(n, 0.02)
        seg = _onopole_lp(seg, 700) * 6.0
        s0 = int(SR * st)
        out[s0:s0 + n] += seg[:total - s0] * 0.8
    tone_n = int(SR * 0.3)
    t = np.arange(tone_n) / SR
    out[:tone_n] += np.sin(2 * math.pi * 240 * t) * _env_exp(tone_n, 0.1) * 0.1
    _write("build", out)
    # celebrate（快速上行 + 闪光）
    total = int(SR * 1.7); out = np.zeros(total)
    seq = [392.0, 493.9, 587.3, 784.0, 987.8, 1174.7]
    for k, f in enumerate(seq):
        st = int(SR * 0.09 * k)
        n = int(SR * 0.6)
        t = np.arange(min(n, total - st)) / SR
        seg = np.sin(2 * math.pi * f * t) * _env_exp(len(t), 0.22)
        out[st:st + len(t)] += seg * 0.22
    for k in range(6):
        f = 1800 + k * 260
        st = int(SR * (0.55 + k * 0.06))
        n = int(SR * 0.25)
        t = np.arange(min(n, total - st)) / SR
        out[st:st + len(t)] += np.sin(2 * math.pi * f * t) * _env_exp(len(t), 0.06) * 0.06
    _write("celebrate", out)

def gen_loops():
    # ambient 16s 环形无缝：和弦垫 + 微风噪声，LFO 周期=整数次
    D = 16.0
    n = int(SR * D)
    t = np.arange(n) / SR
    voices = [(110.0, 0.30), (164.81, 0.22), (220.0, 0.20), (246.94, 0.10), (329.63, 0.12)]
    out = np.zeros(n)
    for k, (f, amp) in enumerate(voices):
        det = 1.0 + (k - 2) * 0.0012
        v = np.sin(2 * math.pi * f * det * t) + 0.3 * np.sin(2 * math.pi * f * det * 2.003 * t)
        lfo = 0.55 + 0.45 * np.sin(2 * math.pi * (k + 1) / D * t + k * 1.3)
        out += v * lfo * amp
    rs = np.random.RandomState(21)
    wind = (rs.rand(n) - 0.5)
    wind = _onopole_lp(wind, 420) * 4.0
    wl = 0.5 + 0.5 * np.sin(2 * math.pi * 2 / D * t + 0.7)
    out += wind * wl * 0.05
    out /= max(1e-6, np.max(np.abs(out)))
    _write("ambient_loop", out * 0.42)
    # rain 8s：低通白噪声 + 周期性强度起伏
    D = 8.0
    n = int(SR * D)
    rs = np.random.RandomState(33)
    r = (rs.rand(n) - 0.5)
    r = _onopole_lp(r, 900) * 5.0
    t = np.arange(n) / SR
    fl = 0.75 + 0.25 * np.sin(2 * math.pi * 3 / D * t)
    r *= fl
    r /= max(1e-6, np.max(np.abs(r)))
    _write("rain_loop", r * 0.34)

if __name__ == "__main__":
    gen_sfx()
    gen_loops()
