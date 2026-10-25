#!/bin/zsh
set -eu
cd "${0:A:h:h}"
engine_bin="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$engine_bin" --headless --path . --editor --import --quit
case "${1:-web}" in
  web) mkdir -p builds/web; "$engine_bin" --headless --path . --export-release Web builds/web/index.html ;;
  macos) mkdir -p builds/macos; "$engine_bin" --headless --path . --export-release macOS builds/macos/YangDaxia.zip; ditto -x -k builds/macos/YangDaxia.zip builds/macos ;;
  windows) mkdir -p builds/windows; "$engine_bin" --headless --path . --export-release Windows builds/windows/YangDaxia.exe ;;
  android) mkdir -p builds/android; "$engine_bin" --headless --path . --export-debug Android builds/android/YangDaxia.apk ;;
  *) echo "Usage: tools/build.sh web|macos|windows|android"; exit 2 ;;
esac
