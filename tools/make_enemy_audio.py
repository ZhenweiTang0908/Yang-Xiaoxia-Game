"""Edit the project's CC0 swishes and Kenney Foley into distinct enemy cues."""
from __future__ import annotations

import json
import subprocess
import wave
from functools import lru_cache
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio"
QA = ROOT / "builds/qa/audio"
RATE = 48_000
FFMPEG = "/opt/homebrew/bin/ffmpeg"
# Identity remains attached to each projectile/zone, rather than its current owner.
PROFILES = {
    "imp:sweep": ("石精·爪击", "claw"),
    "spirit:orb": ("游魂·灵火弹", "orb"),
    "guardian:sweep": ("镇门石卫·重砸", "stone"),
    "pouncer:pounce": ("扑击山魈·扑咬", "pounce"),
    "bat:pounce": ("夜翼蝠·俯冲", "wing"),
    "dart:dart": ("飞针客·三连飞镖", "dart"),
    "shield:sweep": ("盾角兵·盾击", "shield"),
    "shaman:rune": ("引魂师·束缚符", "rune"),
    "lantern:pounce": ("守灯兽·扑击", "stone"),
    "lantern:sweep": ("守灯兽·鹿角横扫", "horn"),
    "lantern:ground_wave": ("守灯兽·地面冲击", "quake"),
    "duelist:flash": ("渡影刀客·快闪刀", "blade"),
    "duelist:triple": ("渡影刀客·三段追身斩", "blade"),
    "duelist:low_sweep": ("渡影刀客·低位扫堂刀", "blade"),
    "duelist:leap": ("渡影刀客·跃起劈落", "stone_blade"),
    "duelist:fan": ("渡影刀客·扇形刀气", "dart"),
    "duelist:boomerang": ("渡影刀客·回旋飞刃", "whirl"),
    "duelist:shadow": ("渡影刀客·影步夹击", "warp"),
    "priest:horn": ("噬月祭主·羊角冲阵", "horn"),
    "priest:four_slash": ("噬月祭主·幽刃四连", "spectral_blade"),
    "priest:ground_wave": ("噬月祭主·地裂波", "quake"),
    "priest:lightning": ("噬月祭主·三连落雷符", "lightning"),
    "priest:ring": ("噬月祭主·环形幽火", "orb"),
    "priest:homing": ("噬月祭主·追魂弹", "homing"),
    "priest:beam": ("噬月祭主·横贯灵束", "beam"),
    "priest:rain": ("噬月祭主·悬刃雨", "rain"),
    "priest:rift": ("噬月祭主·裂隙换位斩", "warp"),
    "priest:ritual": ("噬月祭主·噬月大阵", "ritual"),
}
LAYERS = {
    "claw": [("swish-10", .8), ("impactPunch_medium", .5)],
    "orb": [("impactBell_heavy", .6), ("swish-7", .5)],
    "stone": [("impactMining", .85), ("impactWood_heavy", .6)],
    "pounce": [("impactPunch_heavy", .8), ("swish-6", .6)],
    "wing": [("swish-12", .8), ("impactSoft_medium", .4)],
    "dart": [("swish-3", .7), ("impactMetal_light", .55)],
    "shield": [("impactMetal_heavy", .8), ("impactWood_medium", .5)],
    "rune": [("impactGlass_light", .5), ("impactBell_heavy", .65)],
    "horn": [("swish-9", .7), ("impactWood_heavy", .75)],
    "quake": [("impactMining", .8), ("impactGeneric_light", .45)],
    "blade": [("swish-1", .8), ("impactMetal_medium", .4)],
    "stone_blade": [("swish-6", .65), ("impactMetal_heavy", .6), ("impactMining", .5)],
    "whirl": [("swish-4", .8), ("impactMetal_light", .5)],
    "warp": [("swish-11", .65), ("impactGlass_heavy", .6)],
    "spectral_blade": [("swish-13", .7), ("impactBell_heavy", .35), ("impactMetal_light", .4)],
    "lightning": [("impactGlass_heavy", .75), ("impactMining", .55)],
    "homing": [("impactBell_heavy", .6), ("swish-2", .5)],
    "beam": [("swish-8", .65), ("impactMetal_medium", .5)],
    "rain": [("impactMetal_light", .5), ("impactGlass_light", .45)],
    "ritual": [("impactBell_heavy", .7), ("impactMining", .5), ("swish-5", .4)],
}
MAGIC = {"orb", "rune", "warp", "spectral_blade", "lightning", "homing", "beam", "ritual"}


@lru_cache(maxsize=None)
def read(name: str, variant: int) -> np.ndarray:
    path = (ROOT / f"art_source/audio/swishes/swishes/{name}.wav" if name.startswith("swish")
            else ROOT / f"art_source/audio/kenney-impact/Audio/{name}_{variant:03d}.ogg")
    raw = subprocess.check_output([FFMPEG, "-v", "error", "-i", str(path), "-af",
                                   "highpass=f=65,lowpass=f=7600", "-ar", str(RATE),
                                   "-ac", "1", "-f", "f32le", "pipe:1"])
    return np.frombuffer(raw, dtype="<f4").astype(float)


def pitched(signal: np.ndarray, speed: float) -> np.ndarray:
    return np.interp(np.arange(0, len(signal) - 1, speed), np.arange(len(signal)), signal)


def add(mix: np.ndarray, clip: np.ndarray, at: float, gain: float) -> None:
    start = int(at * RATE)
    count = min(len(clip), len(mix) - start)
    if count > 0:
        mix[start:start + count] += clip[:count] * gain


def save(path: Path, signal: np.ndarray) -> dict:
    signal = signal - signal.mean()
    fade = min(int(.035 * RATE), len(signal) // 4)
    signal[:96] *= np.linspace(0, 1, 96)
    signal[-fade:] *= np.linspace(1, 0, fade)
    rms = max(float(np.sqrt(np.mean(signal * signal))), 1e-9)
    peak = max(float(np.max(np.abs(signal))), 1e-9)
    signal *= min(.13 / rms, .82 / peak)
    assert np.isfinite(signal).all() and np.max(np.abs(signal)) <= .821
    with wave.open(str(path), "wb") as handle:
        handle.setparams((1, 2, RATE, 0, "NONE", ""))
        handle.writeframes((signal * 32767).astype("<i2").tobytes())
    return {"duration": len(signal) / RATE, "peak": float(np.max(np.abs(signal))),
            "rms": float(np.sqrt(np.mean(signal * signal)))}


def main() -> None:
    QA.mkdir(parents=True, exist_ok=True)
    catalog = {}
    manifest = {}
    showcase = np.zeros(int((len(PROFILES) * 2.2 + .2) * RATE))
    for index, (identity, (label, family)) in enumerate(PROFILES.items()):
        source, move = identity.split(":")
        boss = source in {"lantern", "duelist", "priest"}
        speed = {"lantern": .70, "duelist": .98, "priest": .83}.get(source, 1.05) * (1 + (index % 5 - 2) * .07)
        catalog[identity] = {"label": label, "family": family}
        for stage, seconds in [("warning", .48 if family in MAGIC else .28),
                               ("release", .62 if family in {"beam", "ritual", "rain"} else .34),
                               ("impact", .30 if boss else .22)]:
            mix = np.zeros(int(seconds * RATE))
            sources = []
            for layer, (name, gain) in enumerate(LAYERS[family]):
                clip = pitched(read(name, (index + layer) % 5), speed)
                sources.append(name)
                if stage == "warning":
                    clip = clip[::-1]
                    add(mix, clip, .02 + layer * .025, gain * .65)
                elif stage == "release":
                    add(mix, clip, layer * .012, gain)
                    repeats = {"rain": 5, "whirl": 2, "beam": 4, "ritual": 3}.get(family, 1)
                    for repeat in range(1, repeats):
                        add(mix, clip, repeat * .085 + layer * .012, gain * .5 ** repeat)
                else:
                    # A dry body contact anchors the attack's characteristic material.
                    add(mix, clip, layer * .006, gain * .65)
                    add(mix, pitched(read("impactPunch_heavy" if boss else "impactPunch_medium", index % 5), .92), 0, .65)
                if family in MAGIC or source == "priest":
                    add(mix, clip, .075 + layer * .01, gain * .25)
                    add(mix, clip, .14 + layer * .01, gain * .12)
            key = f"enemy_{source}_{move}_{stage}"
            catalog[identity][stage] = key
            metrics = save(OUT / f"{key}.wav", mix)
            manifest[key] = {"identity": identity, "label": label, "family": family,
                             "sources": sources, **metrics}
            with wave.open(str(OUT / f"{key}.wav"), "rb") as handle:
                clip = np.frombuffer(handle.readframes(handle.getnframes()), dtype="<i2") / 32768.0
            add(showcase, clip, index * 2.2 + {"warning": .02, "release": .6, "impact": 1.35}[stage], .85)
    (ROOT / "scripts/core/enemy_audio_catalog.gd").write_text(
        "extends RefCounted\n# Generated by tools/make_enemy_audio.py from CC0 Foley.\nconst PROFILES = "
        + json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (QA / "enemy-audio-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    save(QA / "enemy-attack-showcase.wav", showcase)
    examples = ["imp:sweep", "guardian:sweep", "bat:pounce", "dart:dart", "shield:sweep", "shaman:rune",
                "duelist:flash", "duelist:boomerang", "priest:lightning", "priest:beam", "priest:rain", "priest:ritual"]
    preview = np.zeros(int(len(examples) * 1.1 * RATE))
    preview_index = []
    for index, identity in enumerate(examples):
        preview_index.append({"at": round(index * 1.1, 2), "label": catalog[identity]["label"]})
        for stage, offset in [("release", .02), ("impact", .52)]:
            with wave.open(str(OUT / (catalog[identity][stage] + ".wav")), "rb") as handle:
                clip = np.frombuffer(handle.readframes(handle.getnframes()), dtype="<i2") / 32768.0
            add(preview, clip, index * 1.1 + offset, .85)
    save(QA / "enemy-attack-preview.wav", preview)
    (QA / "enemy-attack-preview.json").write_text(json.dumps(preview_index, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Created {len(catalog)} attack profiles / {len(manifest)} cues; showcase order follows PROFILES.")


if __name__ == "__main__":
    main()
