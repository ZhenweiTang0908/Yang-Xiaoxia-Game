"""Original soundtrack and action audio. Offline PCM synthesis, Vorbis delivery."""
from pathlib import Path
import math, json, wave, subprocess, sys
import numpy as np
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/audio';MUSIC=ROOT/'assets/music'
OUT.mkdir(exist_ok=True);MUSIC.mkdir(exist_ok=True)
SR=24000;rng=np.random.default_rng(731)
kinds=['imp','spirit','guardian','pouncer','bat','dart','shield','shaman']
moves=['pounce','sweep','ground_wave','flash','triple','low_sweep','leap','fan','boomerang','shadow','horn','four_slash','lightning','ring','homing','beam','rain','rift','ritual']
keys=['jump','land','step0','step1','step2','dash','horn','bow','charge','blast','hurt','pickup','checkpoint','death','ui','win','story','ending','transform','revert','ghostflame','sheep_charge','sheep_blast','hit_stone','hit_soft','hit_boss','shield_block','impact_magic','card_throw','card_fan','card_return','card_rune','gourd_open','brother_enter','brother_leave','summon_ready','boss_death']
keys += ['card_draw','card_hit','card_recall','gourd_grow','gourd_close']
keys += ['swing'+str(i) for i in range(1,4)]+['sheep_slash'+str(i) for i in range(1,4)]
keys += [prefix+k for prefix in ['warn_','attack_','death_'] for k in kinds]
keys += ['boss_warn_'+k for k in ['lantern','duelist','priest']]+['boss_'+k for k in moves]
keys=sorted(set(keys))
def write_wav(path,samples,sr=SR):
 samples=np.asarray(samples);samples=np.clip(samples,-.97,.97)
 with wave.open(str(path),'wb') as f:
  f.setparams((1 if samples.ndim==1 else samples.shape[1],2,sr,0,'NONE','not compressed'))
  f.writeframes((samples*32767).astype('<i2').tobytes())
for idx,key in enumerate(keys):
 if key in ["swing1","swing2","swing3","hit_soft","hit_stone","hit_boss","shield_block"] and (OUT/"melee_swing1_0.wav").exists():continue # Authored Foley: regenerate with make_melee_audio.py.
 dur=.14 if key.startswith('step') else (.8 if key in ['transform','revert','gourd_open','brother_enter','brother_leave','boss_death'] else .3)
 if key in ['win','story','ending','checkpoint']:dur=1.4
 if 'charge' in key:dur=1.1
 t=np.arange(int(dur*SR))/SR;env=np.minimum(1,t*100)*np.maximum(0,1-t/dur)**2
 freq=110+(idx*53)%640;noise=rng.uniform(-1,1,len(t))
 if any(k in key for k in ['card','pickup','ready','checkpoint','ui','story','ending','win']):
  y=np.zeros_like(t)
  for j,ratio in enumerate([1,1.25,1.5]):
   u=np.maximum(0,t-j*.07);y+=np.sin(2*np.pi*freq*ratio*u)*np.exp(-u*8)*(t>=j*.07)*.20
  y*=np.minimum(1,t*120)*np.minimum(1,(dur-t)*35)
 elif any(k in key for k in ['hit','blast','death','impact','horn']):
  y=(np.sin(2*np.pi*(65*t-20*t*t))*.52+noise*.27)*env
 elif 'warn' in key:
  y=(np.sin(2*np.pi*(freq*t+120*t*t))*.24+np.sin(2*np.pi*freq*1.5*t)*.12)*env
 else:y=(np.sin(2*np.pi*(freq*t-freq*.6/dur*t*t))*.22+noise*.23)*env
 write_wav(OUT/(key+'.wav'),y)
# Wind bed with a gentle bandlimited noise envelope, rather than harsh white hiss.
t=np.arange(SR*12)/SR;raw=rng.normal(0,1,len(t));wind=np.convolve(raw,np.ones(75)/75,'same')*.18
wind*=.7+.3*np.sin(2*np.pi*t/12);write_wav(OUT/'ambience.wav',wind)
# Six distinct long-form arrangements: pentatonic plucks, bowed pads, bells, bass and percussion.
def compose(stage,boss):
 duration=64 if boss else 96
 sr=SR;n=sr*duration;mix=np.zeros((n,2),dtype=np.float64)
 bpm=112+stage*8 if boss else 76+stage*4
 beat=60/bpm
 scales=[[0,3,5,7,10],[0,2,5,7,9],[0,1,5,7,8]]
 scale=scales[stage-1];root=[50,48,45][stage-1]
 def note(start,length,midi,amp,kind,pan=0):
  begin=int(start*sr)
  if begin>=n:return
  count=min(int(length*sr),n-begin);u=np.arange(count)/sr;f=440*2**((midi-69)/12)
  if kind=='pad':
   attack=np.minimum(1,u/.5);release=np.minimum(1,(length-u)/.7)
   tone=(np.sin(2*np.pi*f*u)+.3*np.sin(2*np.pi*f*1.003*u)+.17*np.sin(2*np.pi*f*2*u))*attack*release
  elif kind=='bell':tone=(np.sin(2*np.pi*f*u)+.3*np.sin(2*np.pi*f*2.01*u)+.1*np.sin(2*np.pi*f*3.93*u))*np.exp(-u*2.8)*np.minimum(1,u*150)
  elif kind=='drum':tone=(np.sin(2*np.pi*(90*u-40*u*u))*np.exp(-u*15)+rng.uniform(-1,1,count)*np.exp(-u*55)*.35)
  else:tone=(np.sin(2*np.pi*f*u)+.28*np.sin(2*np.pi*f*2*u)+.12*np.sin(2*np.pi*f*3*u))*np.exp(-u*4)*np.minimum(1,u*200)
  envelope=np.minimum(1,(length-u)*60)
  mix[begin:begin+count,0]+=tone*amp*envelope*(1-pan*.35)
  mix[begin:begin+count,1]+=tone*amp*envelope*(1+pan*.35)
 bars=int(duration/(beat*4))+1
 motif=[0,2,1,3,4,2,3,1]
 for bar in range(bars):
  start=bar*beat*4;chord=[0,3,4,1][(bar//2)%4]
  base=root+scale[chord%5]-12
  for interval in [0,7,12]:note(start,beat*4.6,base+interval,.055 if boss else .065,'pad',interval/12-.5)
  for step in range(8 if boss else 4):
   phrase=(bar//8)%3;degree=motif[(bar+step)%len(motif)]+phrase
   pitch=root+scale[degree%5]+12*(degree//5)
   note(start+step*beat*(.5 if boss else 1),1.7,pitch,.16 if boss else .12,'pluck',math.sin(step*2)*.5)
  if bar%2==0:note(start+beat*2,3.2,root+12+scale[(bar//2)%5],.09,'bell',.6)
  for step in ([0,1,2,3] if boss else [0,2]):note(start+step*beat,.25,36,.16 if boss else .07,'drum',-.1)
  if boss:
   for step in range(8):note(start+step*beat*.5,.11,root-24,.045,'pluck',-.6)
 # Modest baked stereo echoes; no runtime Web Audio effects required.
 delay=int(.24*sr);mix[delay:]+=mix[:-delay,::-1]*.14
 edge=int(.03*sr);mix[:edge]*=np.linspace(0,1,edge)[:,None];mix[-edge:]*=np.linspace(1,0,edge)[:,None]
 rms=np.sqrt(np.mean(mix*mix));mix*=.16/max(rms,1e-5)
 peak=np.max(np.abs(mix));mix*=min(1,.94/max(peak,1e-5))
 path=MUSIC/f'level{stage}_{"boss" if boss else "explore"}.wav';write_wav(path,mix)
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(path),'-c:a','vorbis','-strict','-2','-q:a','4',str(path.with_suffix('.ogg'))],check=True)
 path.unlink()
 print(path.with_suffix('.ogg').name,duration,'seconds',flush=True)
if "--sfx-only" not in sys.argv:
 for stage in (1,2,3):
  for boss in (False,True):compose(stage,boss)
(ROOT/'scripts/core/audio_catalog.gd').write_text('extends RefCounted\nconst SFX = '+json.dumps(keys,ensure_ascii=False)+'\n')
print('Created',len(keys),'SFX, one ambience bed, and six long-form music tracks.')
