"""Layer existing physical spear / armour Foley into four distinct spear families."""
from pathlib import Path
import json
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio'
RATE=48000

def read(key,speed=1.0,seconds=.4):
    with wave.open(str(OUT/(key+'.wav')),'rb') as f:
        assert f.getframerate()==RATE and f.getsampwidth()==2 and f.getnchannels()==1
        raw=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
    signal=np.interp(np.arange(0,len(raw),speed),np.arange(len(raw)),raw)[:int(seconds*RATE)].copy()
    fade=min(240,len(signal)//4)
    signal[:fade]*=np.linspace(0,1,fade);signal[-fade:]*=np.linspace(1,0,fade)
    return signal

FAMILIES={
 'spear_chain':[
  [('knight_armor',.92,0,.65),('knight_advance_warning',1.10,.06,.5)],
  [('knight_thrust',1.18,0,.9),('knight_lunge_release',1.25,.015,.3)],
  [('knight_hit_thrust',1.12,0,.9),('knight_hit_lance',1.3,.015,.25)]],
 'dragon_sweep':[
  [('knight_switch',.8,0,.7),('knight_armor',1.06,.09,.4)],
  [('knight_lance',.85,0,.7),('knight_uppercut_release',1.18,.065,.5)],
  [('knight_hit_lance',.83,0,.8),('knight_butt',1.1,.03,.3)]],
 'dragon_rise':[
  [('knight_guard',.92,0,.65),('knight_switch',1.12,.07,.4)],
  [('knight_uppercut_release',.90,0,.9),('knight_lance',1.3,.055,.5)],
  [('knight_spear_slam_impact',1.18,0,.8),('knight_hit_thrust',1.0,.02,.3)]],
 'dragon_break':[
  [('knight_wave_raise',.82,0,.7),('knight_guard',.75,.12,.4)],
  [('knight_lance',.72,0,.65),('knight_wave',.92,.04,.85)],
  [('knight_hit_wave',.88,0,.9),('knight_hit_lance',.9,.025,.35)]]}

def main():
    manifest={}
    for family,stages in FAMILIES.items():
        for stage,layers in zip(['warning','release','impact'],stages):
            clips=[(read(key,speed, .5 if family=='dragon_break' else .29),at,gain) for key,speed,at,gain in layers]
            signal=np.zeros(max(int(at*RATE)+len(s) for s,at,gain in clips))
            for s,at,gain in clips:
                start=int(at*RATE);signal[start:start+len(s)]+=s*gain
            signal*=min(.76/max(1e-8,abs(signal).max()),(.075 if stage=='warning' else .13)/max(1e-8,np.sqrt(np.mean(signal*signal))))
            key=f'knight_{family}_{stage}'
            with wave.open(str(OUT/(key+'.wav')),'wb') as f:
                f.setparams((1,2,RATE,0,'NONE',''));f.writeframes((signal*32767).astype('<i2').tobytes())
            manifest[key]={'duration':round(len(signal)/RATE,3),'peak':round(float(abs(signal).max()),3),'rms':round(float(np.sqrt(np.mean(signal*signal))),3)}
    (ROOT/'builds/qa/knight/meteor-audio.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('METEOR_AUDIO',len(manifest),'physical spear cues')
if __name__=='__main__':main()
