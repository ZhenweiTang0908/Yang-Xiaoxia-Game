"""A short bovine call built from a falling voiced source and rounded-vowel formants."""
from pathlib import Path
import numpy as np
import wave
rate=48000
t=np.arange(int(rate*1.35))/rate
frequency=105-28*t/1.35+2*np.sin(t*11)
phase=np.cumsum(frequency)/rate*2*np.pi
signal=np.zeros_like(t)
for harmonic in range(1,36):
 f=frequency*harmonic
 formant=np.exp(-((f-280)/130)**2)+.4*np.exp(-((f-650)/210)**2)+.12*np.exp(-((f-1350)/350)**2)
 signal+=np.sin(phase*harmonic)*formant/harmonic
shape=np.minimum(t/.14,1)*np.minimum((1.35-t)/.24,1)*(1+.10*np.sin(t*21))
signal*=shape
signal*=min(.84/max(abs(signal)),.17/np.sqrt(np.mean(signal*signal)))
with wave.open(str(Path(__file__).resolve().parents[1]/'assets/audio/bull_moo.wav'),'wb') as audio:
 audio.setparams((1,2,rate,0,'NONE',''));audio.writeframes((signal*32767).astype('<i2').tobytes())
