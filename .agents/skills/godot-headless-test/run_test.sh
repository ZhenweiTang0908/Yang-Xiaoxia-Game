#!/usr/bin/env bash
# Run one Godot headless test script with a hard time limit.
# Usage: run_test.sh tests/<name>.gd [timeout_seconds] [extra godot args...]
# Exit: 0 pass, 1 test reported failure, 2 script error, 124 timeout, 64 bad usage.
set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
script="${1:-}"
limit="${2:-300}"
shift $(( $# >= 2 ? 2 : $# ))

if [[ -z "$script" || ! -f "$script" ]]; then
	echo "usage: $0 tests/<name>.gd [timeout_seconds] [extra godot args...]" >&2
	exit 64
fi

name="$(basename "$script" .gd)"
tmp="${TMPDIR:-/tmp}"
log_dir="${tmp%/}/yang-daxia-tests"
mkdir -p "$log_dir"
log="$log_dir/$name.log"
: > "$log"

# 同一个测试已经在跑时，不再重复启动
if pgrep -f -- "--script $script" >/dev/null; then
	echo "ALREADY RUNNING: $script" >&2
	pgrep -fl -- "--script $script" >&2
	exit 64
fi

"$GODOT" --headless --fixed-fps 60 --path . --log-file "$log" --script "$script" "$@" >/dev/null 2>&1 &
pid=$!

stop() {
	kill "$pid" 2>/dev/null
	for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || return; sleep 1; done
	kill -9 "$pid" 2>/dev/null
}
trap 'stop; exit 130' INT TERM

status=""
elapsed=0
while kill -0 "$pid" 2>/dev/null; do
	# GDScript 运行错误会中断协程，quit() 永远不会被调用，进程会一直空转
	if grep -q "SCRIPT ERROR" "$log" 2>/dev/null; then
		sleep 1; stop; status=2; break
	fi
	if (( elapsed >= limit )); then
		stop; status=124; break
	fi
	sleep 1; elapsed=$(( elapsed + 1 ))
done

if [[ -z "$status" ]]; then
	wait "$pid"; status=$?
	grep -q "SCRIPT ERROR" "$log" && status=2
fi

case "$status" in
	0) echo "PASS $script (${elapsed}s)";;
	2) echo "SCRIPT ERROR $script (killed)";;
	124) echo "TIMEOUT $script after ${limit}s (killed)";;
	*) echo "FAIL $script (exit $status)";;
esac
grep -E "SCRIPT ERROR|FAIL |_RESULT" "$log" -A4 | tail -n 40
echo "log: $log"
exit "$status"
