"""Background silent native capture, bounded and tied to the actual Godot PID."""
from pathlib import Path
import subprocess
import time
import os
import signal
import sys
SCRIPT="tests/visual_scale_study.gd" if "--study" in sys.argv else "tests/visual_fixes_capture.gd"
MARKER="VISUAL_SCALE_STUDY_RESULT" if "--study" in sys.argv else "VISUAL_FIXES_CAPTURE_RESULT"
ROOT=Path(__file__).resolve().parents[1]
LOG=Path('/private/tmp/visual-fixes-capture.log')

def pids():
    result=subprocess.run(['pgrep','-f',r'^/Applications/Godot.app/Contents/MacOS/Godot .*--script '+SCRIPT],capture_output=True,text=True)
    if result.returncode not in [0,1]:
        raise RuntimeError('Cannot inspect capture process: '+result.stderr)
    return [int(x) for x in result.stdout.split()]

if pids():
    raise SystemExit('Capture already running; refusing duplicate')
LOG.write_text('')
subprocess.run(['open','-g','-n','-a','/Applications/Godot.app','--args','--path',str(ROOT),'--audio-driver','Dummy','--log-file',str(LOG),'--script',SCRIPT]+(['--','--mount-only'] if '--mount-only' in sys.argv else []),check=True)
seen=set()
start=time.monotonic()
try:
    while time.monotonic()-start<180:
        active=pids()
        seen.update(active)
        text=LOG.read_text() if LOG.exists() else ''
        if 'SCRIPT ERROR' in text or 'ERROR:' in text:
            raise RuntimeError(text[-5000:])
        if MARKER in text and not active:
            print(text[-1200:])
            break
        if seen and not active:
            raise RuntimeError('Capture ended without success marker: '+text[-3000:])
        time.sleep(.5)
    else:
        raise TimeoutError('Capture exceeded 180 seconds')
finally:
    for pid in pids():
        os.kill(pid,signal.SIGTERM)
        for _ in range(10):
            if pid not in pids():break
            time.sleep(.1)
        if pid in pids():os.kill(pid,signal.SIGKILL)
