"""Physical spin/return/charge/volley/sweep cues from existing CC0 knight Foley."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/audio'
FAMILIES={
 'spin_rush':['knight_switch','knight_lance','knight_hit_lance'],
 'spear_return':['knight_wave_raise','knight_lance','knight_hit_thrust'],
 'triple_dash':['knight_armor','knight_thrust','knight_hit_thrust'],
 'bow_volley':['knight_bow_draw','knight_bow_release','knight_hit_arrow'],
 'spear_slam':['knight_guard','knight_hoof_slam','knight_hit_heavy'],
}
def read(key):
 with wave.open(str(OUT/(key+'.wav')),'rb') as f:
  assert f.getsampwidth()==2 and f.getnchannels()==1
  return np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
for index,(key,sources) in enumerate(FAMILIES.items()):
 for stage,source in zip(['warning','release','impact'],sources):
  raw=read(source);speed=[.92,1.14,1.08,.98,.83][index]
  s=np.interp(np.arange(0,len(raw),speed),np.arange(len(raw)),raw)
  if key=='spin_rush' and stage=='release':
   n=int(.075*48000);out=np.zeros(len(s)+n*2)
   for i,gain in enumerate([1,.65,.35]):out[i*n:i*n+len(s)]+=s*gain
   s=out
  if key=='bow_volley' and stage=='release':
   n=int(.012*48000);out=np.zeros(len(s)+2*n)
   for i,gain in enumerate([1,.65,.45]):out[i*n:i*n+len(s)]+=s*gain
   s=out
  s*=min(.8/max(1e-8,abs(s).max()),(.065 if stage=='warning' else .12)/max(1e-8,np.sqrt(np.mean(s*s))))
  with wave.open(str(OUT/f'knight_{key}_{stage}.wav'),'wb') as f:
   f.setparams((1,2,48000,0,'NONE',''));f.writeframes((s*32767).astype('<i2').tobytes())
print('PRESSURE_AUDIO 15 distinct physical cues')
