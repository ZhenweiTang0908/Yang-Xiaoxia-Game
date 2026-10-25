"""Build offline QA audio from events emitted by the animation capture."""
import json
import pathlib
import subprocess
import sys
root = pathlib.Path(__file__).resolve().parents[1]
manifest = json.loads((root / sys.argv[1]).read_text())
frame_pattern = root / sys.argv[2]
output = root / sys.argv[3]
args = ['/opt/homebrew/bin/ffmpeg', '-y', '-framerate', str(manifest['fps']), '-i', str(frame_pattern)]
filters = []
labels = []
for index, event in enumerate(manifest['events'], 1):
    path = root / event['path'].removeprefix('res://')
    args += ['-i', str(path)]
    delay = round(event['frame'] * 48000 / manifest['fps'])
    volume = .6 if 'stone' in path.name else .7
    filters.append(f'[{index}:a]aresample=48000,volume={volume},adelay={delay}S:all=1[a{index}]')
    labels.append(f'[a{index}]')
filters.append(''.join(labels) + f'amix=inputs={len(labels)}:normalize=0,alimiter=limit=0.85:level=false,apad[sound]')
args += ['-filter_complex', ';'.join(filters), '-map', '0:v', '-map', '[sound]', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-c:a', 'aac', '-b:a', '192k', '-t', str(manifest['frames']/manifest['fps']), '-movflags', '+faststart', str(output)]
subprocess.run(args, check=True)
