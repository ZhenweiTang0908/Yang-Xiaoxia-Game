"""Compile the authored dialogue JSON into Godot constant banks; no TTS calls."""
import argparse
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sources():
    bosses=json.loads((ROOT/'data/voice/boss_dialogue.json').read_text())['bosses']
    header='extends RefCounted\n# Authored catalogue: data/voice/boss_dialogue.json.\n'
    knight=bosses['knight']
    return {
        ROOT/'scripts/core/boss_dialogue.gd':header+'const BOSSES='+json.dumps(bosses,ensure_ascii=False,indent=1)+'\n',
        ROOT/'scripts/core/knight_dialogue.gd':header+'const LINES='+json.dumps(knight['lines'],ensure_ascii=False,indent=1)+'\nconst GROUPS='+json.dumps(knight['groups'],ensure_ascii=False,indent=1)+'\n',
    }
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    for path,text in sources().items():
        if args.check:
            if path.read_text()!=text:raise SystemExit('Dialogue bank out of sync: '+path.name)
        else:path.write_text(text)
    print('Dialogue banks match the authored catalogue' if args.check else 'Dialogue banks compiled')
