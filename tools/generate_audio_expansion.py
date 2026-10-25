"""Generate deterministic, original audio layers for the combat mix.

The game keeps authored event sounds as the readable foreground.  These clips
are deliberately broader, quieter layers: low warning pulses, release weight,
finisher air and one ambience bed per stage.
"""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np


RATE = 48_000
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RNG = np.random.default_rng(0x59414E47)


def envelope(length: int, attack: float, release: float) -> np.ndarray:
    env = np.ones(length, dtype=np.float64)
    a = min(length, int(attack * RATE))
    r = min(length, int(release * RATE))
    if a:
        env[:a] = np.sin(np.linspace(0, math.pi / 2, a)) ** 2
    if r:
        env[-r:] *= np.cos(np.linspace(0, math.pi / 2, r)) ** 2
    return env


def smooth_noise(length: int, width: int) -> np.ndarray:
    noise = RNG.normal(0, 1, length + width * 2)
    kernel = np.hanning(width * 2 + 1)
    kernel /= kernel.sum()
    return np.convolve(noise, kernel, mode="same")[width:-width]


def sine_sweep(seconds: float, start_hz: float, end_hz: float, phase=0.0) -> np.ndarray:
    t = np.arange(int(seconds * RATE)) / RATE
    ratio = end_hz / start_hz
    cycles = start_hz * seconds * (ratio - 1) / math.log(ratio) if ratio != 1 else start_hz * seconds
    local = cycles * (np.power(ratio, t / seconds) - 1) / (ratio - 1) if ratio != 1 else start_hz * t
    return np.sin(2 * math.pi * local + phase)


def write(name: str, signal: np.ndarray, peak=0.82) -> None:
    signal = np.nan_to_num(signal)
    signal -= signal.mean()
    current = np.max(np.abs(signal)) or 1.0
    signal = np.tanh(signal / current * 1.45) / np.tanh(1.45) * peak
    pcm = np.asarray(np.clip(signal, -1, 1) * 32767, dtype="<i2")
    with wave.open(str(OUT / name), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(pcm.tobytes())


def impact_heavy() -> np.ndarray:
    seconds = 0.58
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    body = sine_sweep(seconds, 92, 38) * np.exp(-t * 8.0)
    knock = sine_sweep(seconds, 210, 72, 0.4) * np.exp(-t * 14.0)
    grit = RNG.normal(0, 1, n) * np.exp(-t * 24.0)
    grit -= smooth_noise(n, 50)
    return (body * 0.78 + knock * 0.24 + grit * 0.11) * envelope(n, 0.003, 0.16)


def boss_release() -> np.ndarray:
    seconds = 0.82
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    boom = sine_sweep(seconds, 78, 31) * np.exp(-t * 5.2)
    air = smooth_noise(n, 12)
    air -= smooth_noise(n, 180)
    whoosh_env = np.sin(np.clip(t / 0.22, 0, 1) * math.pi / 2) * np.exp(-np.maximum(0, t - 0.18) * 6)
    metal = np.sin(2 * math.pi * (410 * t + 95 * t * t)) * np.exp(-t * 10)
    return (boom * 0.62 + air * whoosh_env * 0.17 + metal * 0.08) * envelope(n, 0.004, 0.24)


def warning_low() -> np.ndarray:
    seconds = 0.92
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    pulse = np.zeros(n)
    for at, hz, gain in [(0.03, 55, 0.75), (0.47, 48, 1.0)]:
        local = np.maximum(0, t - at)
        pulse += np.sin(2 * math.pi * hz * local) * np.exp(-local * 7.5) * (t >= at) * gain
    swell = smooth_noise(n, 110) * np.power(np.clip(t / seconds, 0, 1), 2.2)
    return (pulse + swell * 0.10) * envelope(n, 0.012, 0.08)


def blade_air_heavy() -> np.ndarray:
    seconds = 0.42
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    air = smooth_noise(n, 7) - smooth_noise(n, 100)
    arc = np.sin(np.clip(t / seconds, 0, 1) * math.pi) ** 3
    whistle = sine_sweep(seconds, 900, 310) * arc
    return (air * arc * 0.22 + whistle * 0.12) * envelope(n, 0.035, 0.12)


def transformation_surge() -> np.ndarray:
    seconds = 1.25
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    rise = sine_sweep(seconds, 62, 240) * np.power(np.clip(t / 0.85, 0, 1), 1.6)
    flare = smooth_noise(n, 18) * np.exp(-((t - 0.86) / 0.24) ** 2)
    settle = sine_sweep(seconds, 90, 42) * np.exp(-np.maximum(0, t - 0.82) * 6) * (t > 0.82)
    return (rise * 0.22 + flare * 0.16 + settle * 0.65) * envelope(n, 0.08, 0.24)


def loop_noise(seconds: float, width: int) -> np.ndarray:
    n = int(seconds * RATE)
    raw = RNG.normal(0, 1, n)
    kernel = np.hanning(width * 2 + 1)
    kernel /= kernel.sum()
    # Circular convolution makes the endpoints share the same texture.
    padded = np.concatenate([raw[-width:], raw, raw[:width]])
    return np.convolve(padded, kernel, mode="same")[width:-width]


def ambience(stage: int) -> np.ndarray:
    seconds = 16.0
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    base = loop_noise(seconds, 420 if stage == 1 else 650)
    base /= np.max(np.abs(base)) or 1
    if stage == 1:
        gust = 0.55 + 0.22 * np.sin(2 * math.pi * t / seconds * 3)
        distant = np.sin(2 * math.pi * 176 * t) * (0.5 + 0.5 * np.sin(2 * math.pi * t / seconds)) ** 10
        signal = base * gust * 0.12 + distant * 0.008
    elif stage == 2:
        water = loop_noise(seconds, 85)
        water /= np.max(np.abs(water)) or 1
        reeds = np.sin(2 * math.pi * 2380 * t) * (0.5 + 0.5 * np.sin(2 * math.pi * t / seconds * 11)) ** 24
        signal = base * 0.075 + water * (0.035 + 0.018 * np.sin(2 * math.pi * t / seconds * 5)) + reeds * 0.012
    else:
        hum = np.sin(2 * math.pi * 43 * t) + 0.45 * np.sin(2 * math.pi * 64.5 * t)
        bells = np.zeros(n)
        for at, hz in [(1.0, 196), (6.4, 147), (11.1, 220)]:
            local = np.mod(t - at, seconds)
            bells += np.sin(2 * math.pi * hz * local) * np.exp(-local * 1.15) * (local < 4)
        signal = base * 0.055 + hum * 0.018 + bells * 0.018
    # Every oscillator uses an integer number of cycles and the noise is
    # circularly filtered, so the rendered bed can loop without a seam edit.
    return signal


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write("impact_heavy.wav", impact_heavy(), 0.88)
    write("boss_release.wav", boss_release(), 0.84)
    write("boss_warning_low.wav", warning_low(), 0.72)
    write("blade_air_heavy.wav", blade_air_heavy(), 0.68)
    write("transformation_surge.wav", transformation_surge(), 0.82)
    for stage in (1, 2, 3):
        write(f"ambience_stage{stage}.wav", ambience(stage), 0.24)


if __name__ == "__main__":
    main()
