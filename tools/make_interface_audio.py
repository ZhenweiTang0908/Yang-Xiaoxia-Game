"""Build short, quiet interface cues; no third-party samples required."""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
CUES = {
    'ui_focus': (0.065, (660, 880), 0.12),
    'ui_confirm': (0.16, (660, 990, 1320), 0.18),
    'ui_back': (0.13, (660, 440), 0.15),
    'ui_error': (0.14, (220, 196), 0.13),
}

def build():
    output = Path(__file__).resolve().parents[1] / 'assets/audio'
    for name, (duration, notes, volume) in CUES.items():
        samples = []
        for index in range(int(RATE * duration)):
            t = index / RATE
            signal = 0.0
            for part, frequency in enumerate(notes):
                age = t - part * duration * 0.17
                if age >= 0:
                    envelope = min(age / 0.006, 1) * math.exp(-age / (duration * 0.24))
                    envelope *= min((duration - t) / 0.015, 1)
                    signal += math.sin(math.tau * frequency * age) * envelope
            samples.append(struct.pack('<h', int(signal * volume / len(notes) * 32767)))
        with wave.open(str(output / (name + '.wav')), 'wb') as audio:
            audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            audio.writeframes(b''.join(samples))

if __name__ == '__main__':
    build()
