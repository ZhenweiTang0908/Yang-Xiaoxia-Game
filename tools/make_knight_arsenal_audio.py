"""Six physical attack families, using the project's licensed CC0 Foley."""
import json
from make_knight_audio import buffer, clip, pluck, creak, rumble
from make_enemy_audio import OUT, ROOT, RATE, add, save
import numpy as np

def cut(name, variant=0, speed=1, seconds=.25):
    s=clip(name,variant,speed)[:int(seconds*RATE)].copy()
    n=min(240,len(s)//4)
    s[:n]*=np.linspace(0,1,n);s[-n:]*=np.linspace(1,0,n)
    return s

families={
 'advance':[
  [(cut('footstep_concrete',2,.8),0,.8),(cut('impactPlate_light',1,1.1),.03,.2)],
  [(cut('impactWood_heavy',2,.7),0,1),(cut('impactMining',1,.8),.01,.5)],
  [(cut('impactPunch_heavy',1,.75),0,1),(rumble(.23),0,.3)]],
 'uppercut':[
  [(cut('footstep_grass',2,.8),0,.6),(cut('impactMetal_light',3,.9),.06,.3)],
  [(cut('swish-9',0,.9),0,1),(cut('swish-3',0,1.4),.03,.35)],
  [(cut('impactPunch_heavy',2,1.0),0,1),(cut('impactMetal_medium',1,1.1),0,.25)]],
 'lunge':[
  [(cut('impactPlate_light',2,.9),0,.5),(cut('footstep_concrete',3,1.1),.08,.4)],
  [(cut('swish-3',0,.85),0,1),(cut('footstep_grass',1,.9),0,.25)],
  [(cut('impactPunch_heavy',4,.9),0,1),(cut('impactMetal_light',0,1.1),0,.2)]],
 'kick_thrust':[
  [(cut('impactPlate_light',4,1.2),0,.5),(cut('impactSoft_medium',1,1.0),.07,.4)],
  [(cut('swish-6',0,1.2),0,1)],
  [(cut('impactPunch_medium',3,.9),0,1),(cut('impactSoft_heavy',1,1.0),0,.5)]],
 'bow_double':[
  [(creak(.52),0,1),(cut('impactWood_light',3,1.3,.1),0,.3)],
  [(pluck(209,.21),0,1),(cut('swish-2',0,1.6,.12),.005,.3)],
  [(cut('impactSoft_medium',3,1.3,.16),0,1),(cut('impactWood_light',2,1.4,.1),0,.3)]],
 'cross_cut':[
  [(cut('impactMetal_light',4,.9,.16),0,.6),(cut('swish-12',0,.9,.18),.08,.3)],
  [(cut('swish-1',0,.95,.29),0,1),(cut('swish-6',0,1.4,.15),.04,.2)],
  [(cut('impactPunch_medium',2,.95),0,1),(cut('impactMetal_medium',3,1.15),0,.3)]]
}
manifest={}
for name, stages in families.items():
    for stage,layers in zip(['warning','release','impact'],stages):
        duration=max(at+len(s)/RATE for s,at,_ in layers)+.02
        out=buffer(duration)
        for signal,at,gain in layers:add(out,signal,at,gain)
        key=f'knight_{name}_{stage}'
        manifest[key]=save(OUT/(key+'.wav'),out)
(ROOT/'builds/qa/knight/arsenal-audio.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('ARSENAL_AUDIO',len(manifest))
