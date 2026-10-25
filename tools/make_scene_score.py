"""Deterministic original scene scores; whole-bar loops and restrained combat mix."""
from pathlib import Path
import subprocess, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SR=24000
# Different meters, instrumentation, melodic cells, and harmony for each location.
SCENES=[(1,80,4,50,[0,3,5,7,10],[0,2,1,4,3,2], 'bells'),
        (2,94,3,45,[0,2,3,7,8],[0,4,2,1,3,1], 'strings'),
        (3,66,4,43,[0,1,5,7,8],[0,1,3,2,4,1], 'choir'),
        (4,84,4,38,[0,2,3,5,7],[0,3,4,2,1,0], 'brass')]
def render(stage,bpm,meter,root,scale,motif,color,boss):
 rng=np.random.default_rng(1250+stage+100*boss)
 bpm+=32 if boss else 0; beat=60/bpm; bars=24 if boss else 28
 duration=bars*meter*beat;n=round(duration*SR);mix=np.zeros((n,2))
 def note(at,length,midi,amp,kind,pan=0):
  start=round(at*SR)
  if start>=n:return
  count=min(round(length*SR),n-start);t=np.arange(count)/SR;f=440*2**((midi-69)/12)
  phase=2*np.pi*f*t
  if kind=='drum':
   y=np.sin(2*np.pi*(55*t+22*(1-np.exp(-t*32))/32))*np.exp(-t*12)+rng.normal(0,.12,count)*np.exp(-t*45)
  elif kind=='bells':y=(np.sin(phase)+.27*np.sin(phase*2.01)+.12*np.sin(phase*3.98))*np.exp(-t*2.1)
  elif kind=='pluck':y=(np.sin(phase)+.35*np.sin(phase*2)+.12*np.sin(phase*3))*np.exp(-t*5)
  elif kind=='brass':y=(np.sin(phase)+.28*np.sin(phase*2)+.18*np.sin(phase*3)+.08*np.sin(phase*4))*np.minimum(1,t/.12)
  else:
   y=(np.sin(phase)+.35*np.sin(phase*1.003)+.15*np.sin(phase*2))*np.minimum(1,t/.4)
   if kind=='choir':y*=.8+.2*np.sin(2*np.pi*3.4*t)
  y*=np.minimum(1,t*120)*np.minimum(1,np.maximum(0,length-t)/(.16 if length>.5 else .03))
  mix[start:start+count,0]+=y*amp*np.sqrt((1-pan)/2)
  mix[start:start+count,1]+=y*amp*np.sqrt((1+pan)/2)
 for bar in range(bars):
  at=bar*meter*beat;degree=[0,2,4,1][(bar//2)%4];base=root+scale[degree]
  section=(bar//6)%4
  for interval in [0,7,12]:note(at,meter*beat,base-12+interval,.055 if boss else .07,color,interval/18-.4)
  if color=='choir' and not boss and bar%2:continue
  for j in range(meter*(2 if boss else 1)):
   if not boss and (j+bar)%3==2:continue
   pitch=root+12+scale[motif[(j+bar)%len(motif)]%5]
   note(at+j*beat/(2 if boss else 1),beat*1.4,pitch,.10 if boss else .075,'pluck' if stage==2 else color,np.sin(j*2)*.55)
  # A sparse answering phrase opens and closes each six-bar passage.
  if bar%6 in [3,5]:note(at+(meter-1)*beat,beat,root+24+scale[section],.07,'bells',.6)
  if boss:
   for j in range(meter):
    note(at+j*beat,.32,36,.14 if j==0 else .075,'drum',-.12)
    note(at+(j+.5)*beat,beat*.4,base-12,.055,'pluck',.2)
  elif stage in [2,4]:
   note(at,.28,36,.05,'drum')
 # Circular reflection preserves the musical loop rather than fading every minute.
 mix+=np.roll(mix,round(.21*SR),axis=0)[:,::-1]*.13
 mix*=min(.7/max(np.max(np.abs(mix)),1e-8),.115/max(np.sqrt(np.mean(mix**2)),1e-8))
 # Remove discontinuity only at the sample boundary (2ms), not a musical fade-out.
 edge=48;mix[:edge]*=np.linspace(0,1,edge)[:,None];mix[-edge:]*=np.linspace(1,0,edge)[:,None]
 out=ROOT/'assets/music'/f'level{stage}_{"boss" if boss else "explore"}.ogg';tmp=Path('/private/tmp')/(out.stem+'-score.wav')
 with wave.open(str(tmp),'wb') as f:
  f.setparams((2,2,SR,0,'NONE','not compressed'));f.writeframes((mix*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(tmp),'-c:a','vorbis','-strict','-2','-q:a','5',str(out)],check=True)
 tmp.unlink();print(out.name,round(duration,2),flush=True)
if __name__=='__main__':
 for config in SCENES:
  for boss in [False,True]:render(*config,boss)
