"""Revoice the painted knight with short, physical Foley and contact-only impacts.
Uses the existing CC0 recordings; the previous gourd seal/return are preserved.
"""
import json
import wave
from pathlib import Path
import numpy as np
from make_knight_audio import buffer, clip, lowpass, scrape, rumble, pluck, creak, rng
from make_enemy_audio import RATE, ROOT, add

OUT=ROOT/'assets/audio'
QA=ROOT/'builds/qa/knight'
QA.mkdir(parents=True,exist_ok=True)

def fade(signal,seconds=.025):
    s=signal.copy();n=min(len(s)//3,int(seconds*RATE));s[:min(128,len(s))]*=np.linspace(0,1,min(128,len(s)));s[-n:]*=np.linspace(1,0,n);return s

def dry(name,variant=0,speed=1,length=.18):
    return fade(clip(name,variant,speed)[:int(length*RATE)])

def write(name,s,rms=.10):
    s=fade(s-s.mean());r=max(1e-8,float(np.sqrt(np.mean(s*s))));p=max(1e-8,float(np.max(abs(s))))
    s*=min(rms/r,.85/p)
    assert np.isfinite(s).all() and max(abs(s))<=.851
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE',''));f.writeframes((s*32767).astype('<i2').tobytes())
    return s,dict(duration=round(len(s)/RATE,3),peak=round(float(max(abs(s))),3),rms=round(float(np.sqrt(np.mean(s*s))),3))

sounds={}
def sound(key,seconds,layers,rms=.10):
    s=buffer(seconds)
    for layer,at,gain in layers:add(s,layer,at,gain)
    sounds[key]=(s,rms)

# One individual hoof contact. Runtime emits four contacts per authored gallop.
sound('knight_gallop',.19,[(dry('impactWood_heavy',2,.85,.13),0,.8),(dry('footstep_concrete',1,.8,.14),.007,.8),(dry('impactPlate_light',3,1.2,.08),.035,.12)],.075)
sound('knight_hoof_paw',.30,[(dry('footstep_concrete',3,.8,.15),0,.8),(fade(scrape(.21,.2)),.05,.5)],.065)
# A short breath/snort avoids the previous sustained synthetic high-pitched whinny.
breath=lowpass(rng.normal(0,1,int(.36*RATE)),13)
t=np.arange(len(breath))/RATE
breath*=np.minimum(1,t*50)*np.exp(-t*9)*(.7+.3*np.sin(t*2*np.pi*32))
sound('knight_neigh',.44,[(breath,0,1),(dry('impactSoft_medium',1,.62,.14),.01,.35)],.07)
sound('knight_skid',.42,[(fade(scrape(.34,.4)),0,1),(dry('footstep_grass',2,.7,.18),0,.9),(dry('impactMetal_light',1,.95,.12),.13,.12)],.075)
sound('knight_armor',.20,[(dry('impactPlate_light',1,1.1,.13),0,.7),(dry('impactMetal_light',3,1.25,.09),.055,.3)],.06)
sound('knight_lance',.29,[(dry('swish-9',0,.75,.26),0,1),(dry('impactMetal_light',3,1.1,.10),0,.08)],.115)
sound('knight_hoof_slam',.38,[(dry('impactWood_heavy',3,.65,.2),0,1),(dry('impactMining',2,.75,.22),.015,.7),(rumble(.32),0,.35)],.12)
sound('knight_kick',.22,[(dry('swish-6',0,1.05,.2),0,.8),(dry('impactWood_light',1,.8,.12),0,.15)],.10)
sound('knight_butt',.24,[(dry('swish-6',0,.9,.2),0,.8),(dry('impactMetal_light',2,.85,.1),0,.12)],.09)
sound('knight_thrust',.21,[(dry('swish-3',0,1.15,.19),0,1)],.10)
sound('knight_wave_raise',.21,[(dry('impactPlate_light',1,1.05,.13),0,.6),(dry('swish-5',0,1.15,.12),.05,.18)],.06)
sound('knight_wave',.32,[(dry('swish-8',0,1.05,.28),0,1),(dry('swish-3',0,1.6,.09),0,.55),(rumble(.2),0,.18)],.12)
sound('knight_bow_draw',.68,[(creak(.63),0,1),(dry('impactWood_light',1,1.1,.08),0,.2)],.065)
sound('knight_bow_release',.24,[(pluck(172,.22),0,1),(dry('swish-2',0,1.5,.12),.005,.27)],.10)
sound('knight_sword_grip',.22,[(dry('impactMetal_light',4,1.05,.13),0,.6),(fade(scrape(.16,.2)),0,.7)],.06)
sound('knight_sword_slash',.25,[(dry('swish-1',0,1.1,.24),0,1)],.11)
# Drag texture ends before the raised-sword tell, leaving a readable audible pause.
sound('knight_sword_drag',.73,[(fade(scrape(.68,.32)),0,1),(dry('impactMetal_light',1,.8,.1),.02,.18),(dry('impactMetal_light',3,.9,.1),.38,.16)],.06)
sound('knight_heavy_slash',.32,[(dry('swish-6',0,.85,.30),0,1),(rumble(.21),.04,.2)],.125)
sound('knight_guard',.21,[(dry('impactPlate_heavy',2,.95,.18),0,.7)],.075)
sound('knight_parry',.39,[(dry('impactMetal_heavy',4,1.15,.32),0,1),(dry('impactBell_heavy',1,1.5,.3),0,.12)],.125)
sound('knight_switch',.30,[(dry('impactPlate_light',2,1.1,.11),0,.5),(dry('swish-12',0,1.2,.15),.07,.3),(dry('impactMetal_light',4,1.2,.10),.19,.3)],.06)
sound('knight_dust',.65,[(rumble(.60),0,1),(fade(lowpass(rng.normal(0,1,int(.55*RATE)),12))*np.exp(-np.arange(int(.55*RATE))/RATE*7),0,.5)],.09)
sound('knight_land',.35,[(dry('impactPlate_heavy',0,.8,.25),0,.8),(dry('impactWood_heavy',3,.65,.22),0,.6)],.12)
# Hit-only sounds: spear, hoof, kick, shaft, arrow, light sword, heavy sword, dust.
for key,seconds,layers in [
 ('lance',.32,[(dry('impactPunch_heavy',2,.85,.24),0,.8),(dry('impactMetal_medium',1,1.05,.22),0,.25)]),
 ('hoof',.35,[(dry('impactPunch_heavy',1,.7,.28),0,1),(dry('impactWood_heavy',3,.8,.2),0,.5)]),
 ('kick',.26,[(dry('impactPunch_heavy',0,.9,.22),0,1),(dry('impactSoft_heavy',1,.9,.2),0,.5)]),
 ('butt',.25,[(dry('impactPunch_medium',3,.8,.2),0,1),(dry('impactWood_medium',2,1.0,.2),0,.4)]),
 ('thrust',.24,[(dry('impactPunch_medium',1,1.1,.20),0,1),(dry('impactMetal_light',0,1.2,.12),0,.18)]),
 ('wave',.31,[(dry('impactPunch_heavy',4,.9,.25),0,.8),(dry('swish-3',0,1.2,.13),0,.4)]),
 ('arrow',.20,[(dry('impactSoft_medium',1,1.2,.16),0,1),(dry('impactWood_light',4,1.25,.11),0,.3)]),
 ('sword',.25,[(dry('impactPunch_medium',2,1.1,.22),0,.8),(dry('impactMetal_medium',3,1.25,.18),0,.2)]),
 ('heavy',.38,[(dry('impactPunch_heavy',3,.7,.29),0,1),(dry('impactMetal_heavy',2,.9,.26),0,.25),(rumble(.24),0,.25)]),
 ('dust',.32,[(dry('impactSoft_heavy',4,.8,.25),0,.8),(rumble(.25),0,.3)]),
]:sound('knight_hit_'+key,seconds,layers,.13)
manifest={};showcase=buffer(len(sounds)*.9+.2)
for i,(name,(s,rms)) in enumerate(sounds.items()):
    normalized,info=write(name,s,rms);manifest[name]=info;add(showcase,normalized,i*.9,1)
with wave.open(str(QA/'knight-audio-showcase.wav'),'wb') as f:
    f.setparams((1,2,RATE,0,'NONE',''));f.writeframes((showcase*32767).astype('<i2').tobytes())
(QA/'audio-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('KNIGHT_PHYSICAL_AUDIO',len(manifest),'files, all finite, peaks <= .85')
