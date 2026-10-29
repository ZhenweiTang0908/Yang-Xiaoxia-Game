"""Original sparse pentatonic flute / woodblock / drum score for the fifth duel."""
from pathlib import Path
import json
import subprocess
import wave
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
SR = 24000

def render(boss):
    rng = np.random.default_rng(7520 + boss)
    beat = 60 / (112 if boss else 78)
    bars = 24
    n = round(bars * 4 * beat * SR)
    mix = np.zeros((n, 2))
    def add(at, length, frequency, amp, kind, pan=0):
        start = round(at * SR)
        count = min(round(length * SR), n - start)
        if count <= 0:
            return
        t = np.arange(count) / SR
        if kind == 'wood':
            y = (np.sin(t * 2 * np.pi * 870) + .4 * np.sin(t * 2 * np.pi * 1430)) * np.exp(-t * 42)
        elif kind == 'drum':
            y = np.sin(2 * np.pi * (56 * t + .7 * (1 - np.exp(-t * 35)))) * np.exp(-t * 16)
            y += rng.normal(0, .06, count) * np.exp(-t * 60)
        else:
            phase = 2 * np.pi * frequency * t + .02 * np.sin(t * 2 * np.pi * 4)
            y = (np.sin(phase) + .12 * np.sin(phase * 2)) * np.minimum(1, t / .045)
            y *= np.minimum(1, np.maximum(0, length - t) / .1)
        y *= np.minimum(1, t * 1000)
        mix[start:start+count, 0] += y * amp * np.sqrt((1-pan)/2)
        mix[start:start+count, 1] += y * amp * np.sqrt((1+pan)/2)
    motif = [0, 4, 7, 9, 7, 4, 2, 0]
    for bar in range(bars):
        at = bar * 4 * beat
        # Leave a whole bar of breathing every fourth bar for the elder's voice.
        if bar % 4 != 3:
            for j in [0, 1.5, 3]:
                midi = 69 + motif[(bar+int(j)) % len(motif)]
                add(at + j*beat, beat*.85, 440*2**((midi-69)/12), .065, 'flute', -.25)
        for j in ([0, 1.5, 2, 3.5] if boss else [0, 2]):
            add(at + j*beat, .18, 0, .11 if boss else .055, 'wood', .3)
        add(at, .32, 0, .13 if boss else .045, 'drum')
        if boss and bar % 2:
            add(at + 2.5*beat, .25, 0, .075, 'drum')
    mix += np.roll(mix, round(.17*SR), axis=0)[:, ::-1] * .08
    mix *= min(.65 / max(np.abs(mix).max(), 1e-8), .095 / max(np.sqrt(np.mean(mix**2)), 1e-8))
    mix[:48] *= np.linspace(0, 1, 48)[:, None]
    mix[-48:] *= np.linspace(1, 0, 48)[:, None]
    name = 'level5_' + ('boss' if boss else 'explore')
    temp = Path('/private/tmp') / (name + '.wav')
    with wave.open(str(temp), 'wb') as f:
        f.setparams((2, 2, SR, 0, 'NONE', 'not compressed'))
        f.writeframes((mix * 32767).astype('<i2').tobytes())
    target = ROOT / 'assets/music' / (name + '.ogg')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(temp), '-c:a', 'vorbis', '-strict', '-2', '-q:a', '5', str(target)], check=True)
    temp.unlink()
    return {'path': str(target.relative_to(ROOT)), 'duration': n / SR, 'seed': 7520 + boss, 'source': 'original deterministic synthesis; no sampled recordings'}
if __name__ == '__main__':
    entries = [render(False), render(True)]
    (ROOT / 'assets/music/lion-score-manifest.json').write_text(json.dumps(entries, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps(entries, ensure_ascii=False))
