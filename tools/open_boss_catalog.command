#!/bin/zsh
set -eu
cd "${0:A:h:h}"

port=8769
url="http://127.0.0.1:$port/tools/boss-catalog/"
if ! curl --noproxy '*' -fsS --max-time 1 "$url" >/dev/null 2>&1; then
  .venv/bin/python -m http.server "$port" --bind 127.0.0.1 --directory . >/tmp/yang-daxia-boss-catalog.log 2>&1 &
  for attempt in {1..30}; do
    if curl --noproxy '*' -fsS --max-time 1 "$url" >/dev/null 2>&1; then break; fi
    sleep 0.1
  done
fi
open "$url"
