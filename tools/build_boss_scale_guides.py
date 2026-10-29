"""Calibrate a whole authored pose family from its upright anatomical reference.
Weapon tips, cloak extents, stride and crouch height never change this unit.
"""
from pathlib import Path
import json,sys,math
import numpy as np
from measure_boss_landmarks import rgba,groups,ROOT
OVERRIDES={
 'knight/foot':{1:[105,84,37,40],9:[45,68,25,35]},
 'knight/mounted':{10:[92,104,23,31]},
 'knight/extra':{11:[124,22,30,32]},
 'knight/arsenal':{3:[192,121,45,49],9:[24,51,31,45],11:[129,79,41,37]},
 'knight/pressure':{2:[145,112,38,35],8:[216,79,46,38],11:[68,81,35,44]},
 'reset/knight':{15:[61,22,24,23],16:[70,9,25,24]}}
def baseline(path):
 a=rgba(path);return int(np.where(a[:,:,3]>170)[0].max()+1)
def build():
 candidates=json.loads((ROOT/'builds/qa/visual-stability/landmark-candidates.json').read_text())
 for key,overrides in OVERRIDES.items():
  for index,rect in overrides.items():candidates[key][index]={'head':rect,'reviewed':True}
 profiles={}
 for bank in ['foot','mounted','extra','arsenal','pressure']:
  key='knight/'+bank;heads=candidates[key];target=148.0 if bank=='mounted' else 106.0
  ref={'foot':0,'mounted':0,'extra':9,'arsenal':6,'pressure':0}[bank]
  info=json.loads((ROOT/'assets/art/knight_frames'/bank/'frames.json').read_text())
  extent=info[ref]['baseline']-heads[ref]['head'][1];unit=target/extent
  frames=[]
  for i,h in enumerate(heads):
   frames.append({'unit':unit,'head':h['head'] if h else None,'reference':ref})
  if bank=='extra':
   for i in range(6):frames[i]['unit']=None;frames[i]['head']=None
  profiles[key]={'target_height':target,'frames':frames}
  if bank=='arsenal':
   unit=148.0/(info[0]['baseline']-heads[0]['head'][1])
   profiles['knight/mounted_arsenal']={'target_height':148,'frames':[dict(f,unit=unit,reference=0) for f in frames]}
 for identity,target in [('priest',110.0),('knight',106.0)]:
  key='reset/'+identity;heads=candidates[key];folder=ROOT/'assets/art/boss_reset'/identity
  meta=json.loads((folder/'frames.json').read_text());sources={}
  for i,f in enumerate(meta['frames']):sources.setdefault(f['source'],[]).append(i)
  frames=[None]*meta['count']
  for source,indexes in sources.items():
   reference=indexes[0]
   if identity=='priest' and source.endswith('priest-a.png'):reference=20
   if identity=='priest' and source.endswith('priest-melee.png'):reference=indexes[-1]
   if identity=='priest' and source.endswith('priest-recall.png'):
    base=heads[20]['head'];base_unit=target/(baseline(folder/'20.png')-base[1]);h=heads[reference]['head']
    unit=math.sqrt(base[2]*base[3])*base_unit/math.sqrt(h[2]*h[3])
   else:
    h=heads[reference]['head'];unit=target/(baseline(folder/f'{reference:02}.png')-h[1])
   for i in indexes:
    entry={'unit':round(unit,7),'head':heads[i]['head'] if heads[i] else None,'reference':reference}
    if identity=='priest':
     a=rgba(folder/f'{i:02}.png');r,g,b=[a[:,:,j].astype(float) for j in range(3)]
     cs=[c for c in groups((a[:,:,3]>170)&(r>125)&(g>110)&(b>65)&(r>g*.95)&(r>b*1.03)) if c[4]>=65]
     if cs and heads[i]:
      h=heads[i]['head'];center=np.array([h[0]+h[2]/2,h[1]+h[3]/2])
      focus=max(cs,key=lambda c:np.linalg.norm(np.array([c[0]+c[2]/2,c[1]+c[3]/2])-center))
      entry['focus']=[focus[0]+focus[2]/2,focus[1]+focus[3]/2]
    frames[i]=entry
  profiles[key]={'target_height':target,'frames':frames}
 out=ROOT/'assets/animation/boss_scale_guides.json';out.write_text(json.dumps({'method':'upright anatomical reference per authored family; no bounding-box morph','profiles':profiles},indent=2))
 (ROOT/'builds/qa/visual-stability/landmark-candidates.json').write_text(json.dumps(candidates,indent=2))
 print('BOSS_SCALE_GUIDES_RESULT',len(profiles),'banks',sum(len(p['frames']) for p in profiles.values()),'frames')
if __name__=='__main__':build()
