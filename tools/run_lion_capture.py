"""Background silent native capture, bounded and tied to the actual Godot PID."""
from pathlib import Path
import subprocess
import time
import os
import signal
ROOT=Path(__file__).resolve().parents[1]
LOG=Path('/private/tmp/lion-capture.log')

def pids():
    result=subprocess.run(['pgrep','-f',r'^/Applications/Godot.app/Contents/MacOS/Godot .*--script tests/lion_capture.gd'],capture_output=True,text=True)
    if result.returncode not in [0,1]:
        raise RuntimeError('Cannot inspect capture process: '+result.stderr)
    return [int(x) for x in result.stdout.split()]

if pids():
    raise SystemExit('Capture already running; refusing duplicate')
LOG.write_text('')
subprocess.run(['open','-g','-n','-a','/Applications/Godot.app','--args','--path',str(ROOT),'--audio-driver','Dummy','--log-file',str(LOG),'--script','tests/lion_capture.gd'],check=True)
seen=set()
start=time.monotonic()
try:
    while time.monotonic()-start<90:
        active=pids()
        seen.update(active)
        text=LOG.read_text() if LOG.exists() else ''
        if 'SCRIPT ERROR' in text or 'ERROR:' in text:
            raise RuntimeError(text[-5000:])
        if 'LION_CAPTURE_RESULT' in text and not active:
            print(text[-1200:])
            break
        if seen and not active:
            raise RuntimeError('Capture ended without success marker: '+text[-3000:])
        time.sleep(.5)
    else:
        raise TimeoutError('Capture exceeded 90 seconds')
finally:
    for pid in pids():
        os.kill(pid,signal.SIGTERM)
        for _ in range(10):
            if pid not in pids():break
            time.sleep(.1)
        if pid in pids():os.kill(pid,signal.SIGKILL)
