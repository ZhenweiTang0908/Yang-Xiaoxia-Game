"""Versioned reset dialogue through the bounded, resumable speech generator."""
import argparse
import json
import os
import sys
from pathlib import Path
import generate_boss_voice

if __name__=='__main__':
    root=Path(__file__).resolve().parents[1]
    candidates=[Path.home()/'.codex/skills/tutorial-video-generator/ENV',
                Path.home()/'.claude/skills/tutorial-video-generator/ENV',root/'.env']
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env',type=Path,default=os.environ.get('BOSS_VOICE_ENV'))
    parser.add_argument('--legacy',action='store_true',help='Explicitly generate classic recordings instead of AI')
    args=parser.parse_args()
    env=args.env or next((p for p in candidates if p.is_file()),root/'.env')
    catalog=json.loads((root/'data/voice/boss_dialogue.json').read_text())['bosses']
    identities=[boss+'_'+key for boss in ['lantern','duelist','priest'] for key in catalog[boss]['lines'] if key.startswith('reset_')]
    sys.argv=['generate_boss_voice.py','--env',str(env),'--cache','/private/tmp/boss-reset-ai-tts','--only',','.join(identities)]
    if args.legacy:sys.argv.append('--legacy')
    generate_boss_voice.main()
