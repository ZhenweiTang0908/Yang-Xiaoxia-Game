"""Verify real recorded/generated audio against durable provenance, no provider calls."""
from pathlib import Path
import hashlib
import json
import wave
ROOT=Path(__file__).resolve().parents[2]
checks=0
for name,keys in [('lion_catalogue.json',['assets']),('lion_voice_manifest.json',['ai','classic'])]:
    manifest=json.loads((ROOT/'assets/audio'/name).read_text())
    for section in keys:
        for label,entry in manifest[section].items():
            path=ROOT/entry['path'].removeprefix('res://')
            assert path.is_file(), str(path)
            assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'], label+' hash mismatch'
            with wave.open(str(path),'rb') as audio:
                assert audio.getnframes()>audio.getframerate()*.03, label+' too short'
                assert audio.getnchannels() in [1,2], label+' channel format'
                assert audio.getsampwidth()==2, label+' requires16bit PCM'
                assert abs(audio.getnframes()/audio.getframerate()-entry['duration'])<.04, label+' duration mismatch'
            checks+=1
print(f'LION_AUDIO_ASSETS_RESULT files={checks} failures=0')
