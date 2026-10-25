"""Build the 断誓枪骑 action sounds and the gourd-seal cues.

Hooves, armour, lance, bowstring, blade and gourd each get a distinct family so the
knight's tells can be heard as well as seen. Layers reuse the project's CC0 swishes
and Kenney Foley (see make_enemy_audio.py); the whinny, bowstring and dust bed are
synthesised here.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_enemy_audio import OUT, RATE, add, pitched, read, save  # noqa: E402

rng = np.random.default_rng(4417)


def buffer(seconds: float) -> np.ndarray:
    return np.zeros(int(seconds * RATE))


def clip(name: str, variant: int = 0, speed: float = 1.0) -> np.ndarray:
    return pitched(read(name, variant), speed)


def lowpass(signal: np.ndarray, width: int) -> np.ndarray:
    return np.convolve(signal, np.ones(width) / width, "same")


def envelope(n: int, attack: float, decay: float) -> np.ndarray:
    t = np.arange(n) / RATE
    return np.minimum(1, t / max(attack, 1e-4)) * np.exp(-t * decay)


def whinny(seconds: float = .85) -> np.ndarray:
    t = np.arange(int(seconds * RATE)) / RATE
    contour = 520 + 420 * np.sin(np.clip(t / seconds, 0, 1) * np.pi * .8) - 260 * (t / seconds) ** 2
    vibrato = 1 + .05 * np.sin(2 * np.pi * 24 * t)
    phase = 2 * np.pi * np.cumsum(contour * vibrato) / RATE
    voice = np.sin(phase) * .5 + np.sin(phase * 2) * .22 + np.sin(phase * 3) * .1
    breath = lowpass(rng.normal(0, 1, len(t)), 6) * .25
    return (voice + breath) * np.minimum(1, t * 20) * np.maximum(0, 1 - t / seconds) ** 1.4


def pluck(freq: float, seconds: float) -> np.ndarray:
    # Karplus–Strong string: the bow's release twang.
    period = int(RATE / freq)
    ring = rng.uniform(-1, 1, period)
    out = np.zeros(int(seconds * RATE))
    for i in range(len(out)):
        out[i] = ring[i % period]
        ring[i % period] = .5 * (ring[i % period] + ring[(i + 1) % period]) * .996
    return out


def creak(seconds: float) -> np.ndarray:
    # Wood and string tension: sparse ticks whose rate rises as the bow is drawn.
    n = int(seconds * RATE)
    out = np.zeros(n)
    at = 0.0
    while at < seconds - .02:
        start = int(at * RATE)
        tick = rng.normal(0, 1, 160) * np.exp(-np.arange(160) / 30)
        out[start:start + 160] += tick[: n - start] * (.4 + at / seconds)
        at += .05 - .032 * (at / seconds)
    tone = np.sin(2 * np.pi * (140 + 90 * np.arange(n) / n) * np.arange(n) / RATE) * .08
    return lowpass(out, 3) + tone * np.linspace(0, 1, n)


def scrape(seconds: float, grit: float = 1.0) -> np.ndarray:
    n = int(seconds * RATE)
    noise = rng.normal(0, 1, n)
    band = noise - lowpass(noise, 18)
    wobble = .6 + .4 * np.abs(np.sin(2 * np.pi * 13 * np.arange(n) / RATE + rng.uniform(0, 3)))
    return band * wobble * grit * np.minimum(1, np.arange(n) / (.02 * RATE))


def rumble(seconds: float) -> np.ndarray:
    n = int(seconds * RATE)
    low = lowpass(lowpass(rng.normal(0, 1, n), 120), 60) * 9
    return low * envelope(n, .015, 3.2)


def chime(freqs: list[float], seconds: float) -> np.ndarray:
    t = np.arange(int(seconds * RATE)) / RATE
    return sum(np.sin(2 * np.pi * f * t) * np.exp(-t * (6 + i * 3)) for i, f in enumerate(freqs)) * .3


def build() -> dict[str, np.ndarray]:
    s: dict[str, np.ndarray] = {}
    m = buffer(.5)
    add(m, clip("footstep_concrete", 1, .62), 0, .9); add(m, clip("footstep_concrete", 3, .58), .2, .7)
    add(m, scrape(.18, .25), .02, 1); s["knight_hoof_paw"] = m
    m = buffer(1.0)
    for i, at in enumerate([0, .11, .25, .36, .5, .61, .75, .86]):
        add(m, clip("impactWood_heavy", i % 5, .55 + .04 * (i % 3)), at, .8 - .05 * (i % 2))
    add(m, clip("impactMetal_light", 2, 1.1), .05, .25); add(m, clip("impactMetal_light", 4, 1.2), .55, .22)
    s["knight_gallop"] = m
    m = buffer(.9); add(m, whinny(.85), 0, 1); add(m, clip("impactMetal_light", 1, 1.15), .02, .2)
    s["knight_neigh"] = m
    m = buffer(.5); add(m, scrape(.42, .9) * envelope(int(.42 * RATE), .01, 5), 0, 1)
    add(m, clip("footstep_grass", 2, .6), 0, .8); add(m, clip("impactPlate_light", 0, 1), .05, .3)
    s["knight_skid"] = m
    m = buffer(.7); add(m, clip("impactMining", 2, .55), 0, 1); add(m, clip("impactWood_heavy", 3, .5), .01, .9)
    add(m, rumble(.6), 0, .8); s["knight_hoof_slam"] = m
    m = buffer(.45); add(m, clip("impactPunch_heavy", 1, .72), 0, 1); add(m, clip("impactWood_heavy", 0, .6), .015, .7)
    s["knight_kick"] = m
    m = buffer(.4); add(m, clip("impactPlate_light", 3, 1.05), 0, .8); add(m, clip("impactMetal_light", 0, 1.3), .06, .5)
    s["knight_armor"] = m
    m = buffer(.8); add(m, clip("swish-9", 0, .6), 0, 1); add(m, clip("impactMetal_light", 3, .9), .02, .35)
    s["knight_lance"] = m
    m = buffer(.45); add(m, clip("swish-6", 0, .85), 0, .7); add(m, clip("impactWood_heavy", 2, .7), .07, .9)
    s["knight_butt"] = m
    m = buffer(.4); add(m, clip("swish-3", 0, .88), 0, 1); add(m, clip("impactMetal_light", 2, 1.4), .06, .35)
    s["knight_thrust"] = m
    m = buffer(.45); add(m, clip("swish-5", 0, .72), 0, .55); add(m, clip("impactPlate_light", 1, 1.1), .0, .5)
    s["knight_wave_raise"] = m
    m = buffer(.7); add(m, clip("swish-8", 0, .82), 0, 1); add(m, clip("impactMetal_medium", 1, .8), 0, .55)
    add(m, scrape(.5, .35) * envelope(int(.5 * RATE), .005, 5), .02, 1); s["knight_wave"] = m
    m = buffer(.75); add(m, creak(.7), 0, 1); s["knight_bow_draw"] = m
    m = buffer(.55); add(m, pluck(168, .5) * envelope(int(.5 * RATE), .001, 7), 0, 1); add(m, clip("swish-2", 0, 1.25), .01, .6)
    s["knight_bow_release"] = m
    m = buffer(.4); add(m, clip("impactMetal_light", 4, 1.25), 0, .6); add(m, scrape(.2, .3), .04, 1)
    s["knight_sword_grip"] = m
    m = buffer(.5); add(m, clip("swish-1", 0, .95), 0, 1); add(m, clip("impactMetal_medium", 3, 1.15), .05, .45)
    s["knight_sword_slash"] = m
    m = buffer(.9); add(m, scrape(.82, 1.0) * np.linspace(.4, 1, int(.82 * RATE)), 0, 1)
    add(m, clip("impactMetal_light", 1, .8), 0, .4); add(m, clip("impactMetal_light", 3, .75), .38, .35)
    s["knight_sword_drag"] = m
    m = buffer(.8); add(m, clip("swish-6", 0, .72), 0, 1); add(m, clip("impactMetal_heavy", 2, .8), .06, .8)
    add(m, clip("impactMining", 0, .7), .08, .6); s["knight_heavy_slash"] = m
    m = buffer(.5); add(m, clip("impactPlate_heavy", 2, .8), 0, .9); add(m, clip("impactMetal_light", 0, .9), .05, .3)
    s["knight_guard"] = m
    m = buffer(.6); add(m, clip("impactMetal_heavy", 4, 1.05), 0, 1); add(m, clip("impactBell_heavy", 1, 1.4), 0, .35)
    s["knight_parry"] = m
    m = buffer(.5); add(m, clip("impactPlate_light", 2, .95), 0, .7); add(m, clip("swish-12", 0, 1.1), .06, .45)
    add(m, clip("impactMetal_light", 4, 1.1), .26, .4); s["knight_switch"] = m
    m = buffer(1.2); add(m, clip("impactMining", 4, .5), 0, 1); add(m, rumble(1.1), 0, 1.1)
    add(m, lowpass(rng.normal(0, 1, int(1.1 * RATE)), 9) * envelope(int(1.1 * RATE), .03, 2.6) * .5, 0, 1)
    s["knight_dust"] = m
    m = buffer(.6); add(m, clip("impactPlate_heavy", 0, .78), 0, 1); add(m, clip("impactPunch_heavy", 3, .65), 0, .8)
    s["knight_land"] = m
    m = buffer(.6); add(m, clip("impactWood_light", 2, .9), 0, .8)
    t = np.arange(int(.45 * RATE)) / RATE
    add(m, np.sin(2 * np.pi * (520 * t - 380 * t * t)) * np.exp(-t * 6) * .35, .02, 1)
    add(m, clip("impactWood_light", 4, .75), .32, .7); s["gourd_seal"] = m
    m = buffer(.55); add(m, clip("swish-7", 0, 1.3), 0, .55); add(m, chime([880, 1320, 1760], .5), .22, 1)
    s["gourd_return"] = m
    return s


def main() -> None:
    for key, signal in build().items():
        info = save(OUT / f"{key}.wav", signal)
        print(f"{key}: {info['duration']:.2f}s peak={info['peak']:.2f}")


if __name__ == "__main__":
    main()
