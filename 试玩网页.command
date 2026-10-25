#!/bin/zsh
set -eu
cd "${0:A:h}"
if curl -fsS http://127.0.0.1:8765/index.html >/dev/null 2>&1; then
  open -a 'Google Chrome' http://127.0.0.1:8765
  exit 0
fi
open -a 'Google Chrome' http://127.0.0.1:8765
if [[ -x .venv/bin/python ]]; then
  .venv/bin/python tools/serve_web.py
else
  python3 tools/serve_web.py
fi
