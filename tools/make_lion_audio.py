"""Build lion elder material cues from the project's licensed CC0 Foley only.

Run with .venv/bin/python tools/make_lion_audio.py. Voice is generated separately
by generate_boss_voice.py; this builder never fabricates speech or breath.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import numpy as np
from make_enemy_audio import ROOT, OUT, RATE, read, pitched, add, save

MOVES = ['pounce','wash_foot','lion_slam','lion_roll','back_kick','high_sweep',
         'lion_sleep','lion_steps','cup_elbow','lean_kick','sit_kick','ground_roll',
         'handstand','turn_kick','toss_palm','shuffle','double_palm','twist',
         'lion_finale','drunk_finale']
BEATS = {name: count for name, count in zip(MOVES, [1,1,1,1,1,1,1,3,1,1,1,2,1,1,1,1,2,2,2,3])}
EXTRAS = {'step_left':3,'step_right':3,'turn':2,'eye':2,'cloth':2,'hurt':3,
          'counter_head':2,'counter_gourd':2,'counter_support':2,'sit':2,
          'protect_lamp':2,'phase_2':2,'defeat':2}
# Low-energy soft contacts stand for fabric and paper; no metal, drums or tones.
WOOD = 'impactWood_light'
CLOTH = 'impactSoft_medium'
SHOE = 'footstep_carpet'
GROUND = 'footstep_concrete'
BODY = 'impactPunch_medium'


def build():
    catalogue = {'version':1, 'moves':BEATS, 'events':{}, 'assets':{},
                 'license_evidence':['art_source/audio/kenney-impact/License.txt',
                             'docs/scene-combat-audio.md']}
    def emit(key, layers):
        clips = []
        sources = []
        for name, variant, speed, at, gain in layers:
            signal = pitched(read(name, variant), speed)[:int(.38 * RATE)].copy()
            fade = min(240, len(signal)//4)
            signal[:fade] *= np.linspace(0,1,fade)
            signal[-fade:] *= np.linspace(1,0,fade)
            clips.append((signal, at, gain))
            path = (ROOT/f'art_source/audio/swishes/swishes/{name}.wav' if name.startswith('swish')
                    else ROOT/f'art_source/audio/kenney-impact/Audio/{name}_{variant:03d}.ogg')
            sources.append({'path':str(path.relative_to(ROOT)), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                            'speed':speed,'at':at,'gain':gain})
        mix = np.zeros(int((max(at+len(s)/RATE for s,at,_ in clips)+.025)*RATE))
        for signal, at, gain in clips:
            add(mix, signal, at, gain)
        path = OUT/(key+'.wav')
        quality = save(path, mix)
        catalogue['assets'][key] = {'path':'res://assets/audio/'+path.name, 'sources':sources,
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), **quality}
        return key
    for index, move in enumerate(MOVES):
        for beat in range(1, BEATS[move]+1):
            variant = (index+beat)%5
            speed = round(.88 + index*.011 + beat*.025,3)
            head = index < 8 or (move == 'lion_finale' and beat == 1)
            stages = {
                'warning':[(WOOD if head else CLOTH, variant, speed, 0,.65)],
                'charge':[(SHOE,variant,speed*.9,0,.65),(CLOTH,(variant+1)%5,1.1,.09,.4)],
                'release':[(f'swish-{(index+beat)%13+1}',0,speed,0,.85),(CLOTH,variant,1.2,.025,.25)],
                'impact':[(BODY,variant,speed,0,.9),(WOOD if head else 'impactSoft_medium',(variant+2)%5,speed,.015,.45)],
                'landing':[(GROUND,variant,speed,0,.55),(SHOE,(variant+1)%5,speed,.075,.4)],
                'recover':[(CLOTH,variant,speed,0,.6),(WOOD if head else SHOE,(variant+1)%5,speed,.08,.3)],
            }
            if move == 'lion_steps':
                stages['release'] = [(GROUND,variant,speed,0,.65)]
            if move == 'handstand':
                stages['charge'] = [('impactSoft_medium',variant,1.2,0,.5),(CLOTH,variant,1.1,.06,.3)]
            if move == 'toss_palm':
                stages['warning'] = [(WOOD,variant,1.2,0,.55)]
                stages['charge'] = [(WOOD,(variant+1)%5,1.4,0,.4)]
                stages['recover'] = [(WOOD,variant,.85,0,.7),(CLOTH,variant,1,.04,.3)]
            for stage, layers in stages.items():
                event = f'lion:{move}:{beat}:{stage}'
                catalogue['events'][event] = emit(f'lion_{move}_{beat}_{stage}', layers)
    for extra_index, (event, count) in enumerate(EXTRAS.items()):
        family = (WOOD if event in ['eye','counter_head','counter_gourd','protect_lamp','phase_2']
                  else BODY if event == 'hurt' else CLOTH if event == 'cloth' else SHOE)
        for variant in range(count):
            catalogue['events'][f'lion:{event}:{variant+1}:material'] = emit(
                f'lion_{event}_{variant+1}_material',[(family,variant,round(.86+variant*.09+extra_index*.013,3),0,.65)])
    (OUT/'lion_catalogue.json').write_text(json.dumps(catalogue,ensure_ascii=False,indent=2)+'\n')
    print('LION_AUDIO', len(catalogue['assets']), 'material WAVs; human vocalizations are separate')

if __name__ == '__main__':
    build()
