"""Distinct reset Foley stages using project's licensed source bank."""
import json
from pathlib import Path
import numpy as np
from make_enemy_audio import read,pitched,add,save,RATE
ROOT=Path(__file__).resolve().parents[1]
def main():
 definitions=json.loads((ROOT/'art_source/boss_reset/move_definitions.json').read_text())
 profiles={}
 for boss,moves in definitions.items():
  for index,m in enumerate(moves):
   name='reset_'+boss+'_'+m['id'];profile={}
   for si,stage in enumerate(['warning','charge','release','impact','landing','recover']):
    mix=np.zeros(int(RATE*(.28 if stage in ['release','impact'] else .48)),np.float32)
    source={'lantern':['impactWood_light','impactMining','swish-9','impactMining','impactWood_heavy','footstep_concrete'], 'duelist':['impactMetal_light','swish-3','swish-1','impactMetal_medium','footstep_concrete','swish-4'], 'priest':['swish-7','impactBell_heavy','swish-8','impactGlass_light','impactSoft_medium','swish-2']}[boss][si]
    clip=pitched(read(source,1),(.85 if boss=='lantern' else 1.1)+(index%4)*.035)
    add(mix,clip,0,.65 if stage=='impact' else .30)
    if boss=='priest':
     t=np.arange(len(mix))/RATE
     tone=np.sin(2*np.pi*(330+index*9)*t)*np.sin(np.pi*np.minimum(t/.35,1))**2*np.exp(-t*7)*.08
     mix+=tone
    file=name+'_'+stage
    save(ROOT/'assets/audio'/f'{file}.wav',mix);profile[stage]=file
   profiles['reset_'+boss+':'+m['id']]=profile
 text='extends RefCounted\nconst PROFILES='+json.dumps(profiles,ensure_ascii=False,indent=1)+'\n'
 (ROOT/'scripts/core/reset_audio_catalog.gd').write_text(text)
 moon=np.zeros(int(RATE*.52),np.float32);add(moon,pitched(read('swish-8',1),1.3),0,.55);add(moon,pitched(read('impactGlass_light',1),.8),.08,.32)
 save(ROOT/'assets/audio/reset_moon_fall.wav',moon)
 print('RESET_AUDIO_RESULT profiles='+str(len(profiles)))
if __name__=='__main__':main()
