"""AIHubMix speech only: bounded calls, resumable cache, no credentials in output.

The ENV parser and /audio/speech request follow tutorial-video-generator.
Primary plus one fallback maximum per line. No browser or video generation.
"""
import argparse
import concurrent.futures
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import threading
import urllib.error
import urllib.request
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 48000
VERSION = 2

def load_env(path):
    for raw in Path(path).read_text().splitlines():
        match = re.match(r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', raw.strip())
        if not match:
            continue
        key, value = match.groups()
        if len(value) > 1 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        if value and key not in os.environ:
            os.environ[key] = value
    if not all(os.environ.get(key) for key in ['AI_HUB_BASEURL', 'AI_HUB_APIKEY']):
        raise RuntimeError('Missing speech service configuration in ENV')

def endpoint():
    base = os.environ['AI_HUB_BASEURL'].rstrip('/')
    if base.endswith('/audio/speech'):
        return base
    from urllib.parse import urlsplit
    url = urlsplit(base)
    if url.scheme != 'https' or not url.netloc:
        raise RuntimeError('Speech service requires an HTTPS base URL')
    return base + ('/v1' if not url.path else '') + '/audio/speech'

def unwrap(data):
    if data[:4] != b'RIFF' or data[8:12] != b'WAVE':
        raise RuntimeError('Provider did not return WAV audio')
    offset = 12
    while offset + 8 <= len(data):
        length = int.from_bytes(data[offset+4:offset+8], 'little')
        payload = offset + 8
        if data[offset:offset+4] == b'data':
            nested = data[payload:payload+length]
            if nested[:4] == b'RIFF' and nested[8:12] == b'WAVE':
                size = int.from_bytes(nested[4:8], 'little') + 8
                if size > len(nested):
                    raise RuntimeError('Truncated nested WAV')
                return nested[:size]
            break
        offset = payload + length + length % 2
    return data

def request_speech(text, model, voice, instructions=""):
    request = urllib.request.Request(endpoint(), data=json.dumps({
        'model': model, 'voice': voice, 'input': text,
        'response_format': 'wav', 'language': 'zh', 'instructions': instructions,
    }, ensure_ascii=False).encode(), headers={
        'Authorization': 'Bearer ' + os.environ['AI_HUB_APIKEY'],
        'Content-Type': 'application/json',
    }, method='POST')
    try:
        with urllib.request.urlopen(request, timeout=100) as response:
            data = response.read(24 * 1024 * 1024)
    except urllib.error.HTTPError as error:
        raise RuntimeError('Speech provider HTTP ' + str(error.code)) from None
    except (urllib.error.URLError, TimeoutError, OSError):
        raise RuntimeError('Speech provider connection failed or timed out') from None
    return unwrap(data)

def process_audio(raw, destination, boss, effort=False):
    decoded = subprocess.run(['ffmpeg', '-v', 'error', '-i', 'pipe:0', '-ac', '1',
        '-ar', str(RATE), '-af', 'highpass=f=75,lowpass=f=8000', '-f', 'f32le', 'pipe:1'],
        input=raw, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
    if decoded.returncode:
        raise RuntimeError('Provider audio failed PCM decoding')
    audio = np.frombuffer(decoded.stdout, dtype='<f4').copy()
    if not (.3 * RATE <= len(audio) <= 15 * RATE) or not np.isfinite(audio).all():
        raise RuntimeError('Speech duration or samples invalid')
    rms = float(np.sqrt(np.mean(audio * audio)))
    if rms < .001:
        raise RuntimeError('Provider speech is silent')
    tail = audio[-int(.25*RATE):]
    before = audio[-int(.75*RATE):-int(.25*RATE)]
    trimmed = False
    if len(before) and np.max(np.abs(tail)) >= .94 and np.max(np.abs(tail)) > 2*np.max(np.abs(before)):
        audio = audio[:-int(.22*RATE)];trimmed = True
    if float(np.mean(np.abs(audio) >= .9999)) > .01:
        raise RuntimeError('Provider speech is persistently clipped')
    if effort:
        # Keep the first exertion, not a long breath/tail or repeated syllables.
        envelope = np.convolve(np.abs(audio), np.ones(480)/480, mode='same')
        active = np.flatnonzero(envelope > max(.008, float(envelope.max())*.12))
        if len(active):
            onset = max(0, int(active[0])-960)
            end = min(int(active[-1])+2400, onset+int(.88*RATE))
            audio = audio[onset:end]
    # A tiny reflection, different from words or a long reverb tail, preserves consonants.
    if boss in ['knight', 'priest']:
        delay = int((.027 if boss == 'knight' else .052) * RATE)
        audio[delay:] += (.07 if boss == 'knight' else .10) * audio[:-delay].copy()
    audio *= min(.85/max(1e-8, float(np.max(np.abs(audio)))),
                 .105/max(1e-8, float(np.sqrt(np.mean(audio*audio)))))
    audio[:240] *= np.linspace(0, 1, 240)
    audio[-960:] *= np.linspace(1, 0, 960)
    with wave.open(str(destination), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', ''))
        wav.writeframes((audio * 32767).astype('<i2').tobytes())
    return {'duration': round(len(audio)/RATE, 4), 'peak': round(float(np.max(np.abs(audio))), 4),
            'rms': round(float(np.sqrt(np.mean(audio*audio))), 4), 'tail_trimmed': trimmed}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env', required=True)
    parser.add_argument('--cache', required=True)
    parser.add_argument('--samples', action='store_true')
    parser.add_argument('--efforts', action='store_true', help='Generate short combat exertions only')
    parser.add_argument('--legacy', action='store_true', help='Make only missing local classic recordings; no API calls')
    args = parser.parse_args()
    catalog = json.loads((ROOT/'data/voice/boss_dialogue.json').read_text())
    cache = Path(args.cache);cache.mkdir(parents=True, exist_ok=True)
    manifest_file = cache/'manifest.json'
    manifest = json.loads(manifest_file.read_text()) if manifest_file.exists() else {}
    jobs = []
    for boss, bank in catalog['bosses'].items():
        for line, text in (bank['efforts'] if args.efforts else bank['lines']).items():
            if args.samples and line != 'intro':
                continue
            jobs.append((boss, line, text, bank['voice']))
    if args.legacy:
        for boss, line, text, _ in jobs:
            output = ROOT/'assets/voice'/f'{boss}_{line}.wav'
            if output.exists():
                continue
            source = cache/f'{boss}_{line}.aiff'
            result = subprocess.run(['say','-v','Reed (Chinese (China mainland))','-r','188','-o',str(source),text],
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
            if result.returncode:
                raise RuntimeError('Classic speech service failed for ' + boss + '_' + line)
            raw = subprocess.run(['ffmpeg','-v','error','-i',str(source),'-f','wav','pipe:1'],
                                 stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True,timeout=30).stdout
            process_audio(raw, output, boss)
        print('CLASSIC recordings complete; original files untouched', flush=True)
        return
    load_env(args.env)
    output_dir = ROOT/'assets/voice/ai';output_dir.mkdir(parents=True, exist_ok=True)
    lock = threading.Lock();stop = threading.Event();failures = []
    queue = iter(jobs)
    def record(identity, value):
        manifest[identity] = value
        temporary = manifest_file.with_suffix('.tmp')
        temporary.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
        temporary.replace(manifest_file)
    def worker():
        while not stop.is_set():
            with lock:
                try: boss,line,text,voice = next(queue)
                except StopIteration: return
            identity = boss+'_'+line
            instructions = catalog['bosses'][boss]['performance']
            if args.efforts:
                instructions += ' 只发出一个短促、爆发的战斗发力喊声，0.3到0.7秒，不能添加其他字词。'
            elif line.startswith('death'):
                instructions += ' 此句是战败遗言，虚弱但保留角色个性，不要怒吼。'
            fingerprint = hashlib.sha256(json.dumps([VERSION,text,catalog['model'],voice,instructions],ensure_ascii=False).encode()).hexdigest()
            destination = output_dir/(identity+'.wav')
            previous = manifest.get(identity, {})
            if previous.get('fingerprint') == fingerprint:
                if previous.get('error'):
                    stop.set();failures.append(identity+': previous primary and fallback attempts failed; no automatic retry')
                    return
                if destination.exists() and previous.get('sha256') == hashlib.sha256(destination.read_bytes()).hexdigest():
                    print('CACHE '+identity, flush=True);continue
            errors = []
            for index,(model,chosen) in enumerate([(catalog['model'],voice),(catalog['fallback_model'],catalog['fallback_voice'])]):
                try:
                    raw = request_speech(text,model,chosen,instructions)
                    raw_file = cache/(identity+f'.{index}.raw.wav');raw_file.write_bytes(raw)
                    staging = cache/(identity+'.ready.wav')
                    quality = process_audio(raw, staging, boss, args.efforts)
                    shutil.copyfile(staging, destination)
                    with lock:
                        record(identity, {'fingerprint':fingerprint,'text':text,'boss':boss,'model':model,
                            'voice':chosen,'instructions':instructions,'fallback':bool(index),'attempts':index+1,'primary_error':errors[0] if errors else None,
                            'sha256':hashlib.sha256(destination.read_bytes()).hexdigest(), **quality})
                    print('GENERATED '+identity+' '+model+' '+chosen+' '+str(quality['duration'])+'s', flush=True)
                    break
                except (RuntimeError,subprocess.SubprocessError,wave.Error) as error:
                    errors.append(str(error))
                    print('ATTEMPT_FAILED '+identity+' '+model+' '+str(error),flush=True)
            else:
                stop.set()
                with lock:
                    record(identity, {'fingerprint':fingerprint,'error':' / '.join(errors),'attempts':2})
                    failures.append(identity+': '+' / '.join(errors))
                return
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(worker) for _ in range(2)]
        for future in futures:
            future.result()
    if failures:
        raise SystemExit('TTS stopped: '+'; '.join(failures))
    print('BOSS_AI_VOICE_COMPLETE '+str(len(jobs)),flush=True)

if __name__ == '__main__':
    main()
