"""Purple eagle cry and divine spear cues made from procedural tones and owned Foley."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
RATE=48000
rng=np.random.default_rng(251025)
def save(name,s):
 s*=min(.88/max(1e-8,np.max(np.abs(s))),.13/max(1e-8,np.sqrt(np.mean(s*s))))
 s[:240]*=np.linspace(0,1,240);s[-720:]*=np.linspace(1,0,720)
 with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
  f.setparams((1,2,RATE,0,'NONE',''));f.writeframes((s*32767).astype('<i2').tobytes())
t=np.arange(int(RATE*1.0))/RATE
freq=1700-1050*t+160*np.sin(t*34)
phase=np.cumsum(freq)/RATE*2*np.pi
env=np.sin(np.pi*np.minimum(t/.08,1)/2)*np.exp(-t*3)*(1+.22*np.sin(t*95))
save('knight_eagle_cry',(np.sin(phase)+.3*np.sin(phase*2.02)+rng.normal(0,.12,len(t)))*env)
for name,source,speed in [('knight_divine_rise','knight_guard',.8),('knight_divine_throw','knight_lance',.7),('knight_divine_pin','knight_hit_heavy',.85)]:
 with wave.open(str(ROOT/(source+'.wav')),'rb') as f:
  raw=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
 s=np.interp(np.arange(0,len(raw),speed),np.arange(len(raw)),raw)
 t=np.arange(len(s))/RATE
 s+=.08*np.sin(2*np.pi*(420*t+180*t*t))*np.exp(-t*5)
 save(name,s)
