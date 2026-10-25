"""Reproducible edit of CC0 recorded swishes and Kenney impacts. No synthetic chirps."""
from pathlib import Path
import subprocess, wave, json, shutil
import numpy as np
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/audio';QA=ROOT/'builds/qa/audio';QA.mkdir(parents=True,exist_ok=True)
SR=48000;FF='/opt/homebrew/bin/ffmpeg';manifest={}
for name in ['swing1','swing2','swing3','hit_soft','hit_stone','hit_boss','shield_block']:
 backup=QA/('old_'+name+'.wav')
 if not backup.exists():shutil.copy2(OUT/(name+'.wav'),backup)
def read(path):
 raw=subprocess.check_output([FF,'-v','error','-i',str(path),'-af','highpass=f=100,lowpass=f=6800','-ar',str(SR),'-ac','1','-f','f32le','pipe:1'])
 x=np.frombuffer(raw,dtype='<f4').astype(float);return x-x.mean()
def save(name,x,sources):
 x=np.asarray(x);x[:192]*=np.linspace(0,1,192);x[-960:]*=np.linspace(1,0,960)
 assert np.isfinite(x).all() and abs(x).max()<.92
 with wave.open(str(OUT/(name+'.wav')),'wb') as f:
  f.setparams((1,2,SR,0,'NONE',''));f.writeframes((x*32767).astype('<i2').tobytes())
 manifest[name]={'sources':sources,'duration':len(x)/SR,'peak_db':float(20*np.log10(max(abs(x).max(),1e-9))),'rms_db':float(20*np.log10(max(np.sqrt(np.mean(x*x)),1e-9)))}
def fit(x,duration,peak_time):
 energy=np.convolve(x*x,np.ones(240)/240,'same');peak=int(np.argmax(energy))
 start=peak-int(peak_time*SR);length=int(duration*SR);out=np.zeros(length)
 a=max(0,start);b=min(len(x),start+length)
 if b>a:out[a-start:b-start]=x[a:b]
 return out
def normalize(x,rms,peak):
 return x*min(rms/max(np.sqrt(np.mean(x*x)),1e-9),peak/max(abs(x).max(),1e-9))
for combo,ids in enumerate([[10,11,12],[1,3,4],[6,7,9]],1):
 for variant,number in enumerate(ids):
  src=ROOT/f'art_source/audio/swishes/swishes/swish-{number}.wav';x=read(src)
  x=fit(x,[.16,.18,.23][combo-1],[.035,.04,.055][combo-1])
  x=normalize(x,[.10,.112,.14][combo-1],[.5,.55,.64][combo-1])
  save(f'melee_swing{combo}_{variant}',x,[str(src.relative_to(ROOT))])
 for_alias=OUT/f'melee_swing{combo}_0.wav';shutil.copy2(for_alias,OUT/f'swing{combo}.wav')
base=ROOT/'art_source/audio/kenney-impact/Audio'
for material in ['soft','stone','boss','block']:
 for combo in range(1,4):
  for variant in range(3):
   rows={'soft':[('impactPunch_heavy' if combo==3 else 'impactPunch_medium',.85),('impactSoft_heavy' if combo==3 else 'impactSoft_medium',.25)],'stone':[('impactMining',.75),('impactWood_heavy' if combo==3 else 'impactWood_medium',.32)],'boss':[('impactWood_heavy',.65),('impactPunch_heavy',.55)],'block':[('impactMetal_medium',.65),('impactWood_medium',.2)]}[material]
   length=[.17,.19,.235][combo-1];x=np.zeros(int(length*SR));sources=[]
   for label,gain in rows:
    src=base/f'{label}_{variant:03d}.ogg';y=fit(read(src),length,.006)
    y=normalize(y,.12,.75);x+=y*gain;sources.append(str(src.relative_to(ROOT)))
   x*=np.exp(-np.arange(len(x))/SR/(.085 if material!='block' else .065))
   x=normalize(x,[.105,.11,.125][combo-1],[.62,.65,.70][combo-1]);save(f'melee_{material}{combo}_{variant}',x,sources)
for alias,material in [('hit_soft','soft'),('hit_stone','stone'),('hit_boss','boss'),('shield_block','block')]:shutil.copy2(OUT/f'melee_{material}1_0.wav',OUT/f'{alias}.wav')
(QA/'melee-manifest.json').write_text(json.dumps(manifest,indent=2))
# Audible comparison: old three hits, pause, new whiffs, pause, new soft hits, pause, stone hits.
def pcm(path):
 return np.frombuffer(subprocess.check_output([FF,'-v','error','-i',str(path),'-ar',str(SR),'-ac','1','-f','f32le','pipe:1']),dtype='<f4')
mix=np.zeros(SR*9)
def add(at,path,gain=1):
 x=pcm(path)*gain;i=int(at*SR);mix[i:i+len(x)]+=x
for start,kind in [(.4,'old'),(2.3,'whiff'),(4.2,'soft'),(6.3,'stone')]:
 for combo,offset in enumerate([0,.27,.56],1):
  hit=start+offset+[.15,.17,.22][combo-1]
  if kind=='old':add(hit-.035,QA/f'old_swing{combo}.wav',.562);add(hit,QA/'old_hit_soft.wav',.398)
  else:
   add(hit-[.035,.04,.055][combo-1],OUT/f'melee_swing{combo}_0.wav',.562)
   if kind!='whiff':add(hit,OUT/f'melee_{kind}{combo}_0.wav',.708)
assert abs(mix).max()<.95
with wave.open(str(QA/'normal-attack-comparison.wav'),'wb') as f:
 f.setparams((1,2,SR,0,'NONE',''));f.writeframes((mix*32767).astype('<i2').tobytes())
print('Edited',len(manifest),'clips; comparison peak',round(20*np.log10(abs(mix).max()),2),'dBFS')
