#!/usr/bin/env bash
# The GDScript "typecheck": refreshes the global class cache, then compiles every
# script in the project and fails if any has a parse or type error.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-flatpak run org.godotengine.Godot}"
$GODOT --headless --path . --editor --quit >/dev/null 2>&1
out=$($GODOT --headless --path . -s tools/check.gd 2>&1)
status=$?
if [ $status -ne 0 ]; then
	echo "$out" | grep -E -B1 -A1 "SCRIPT ERROR|Parse Error|check: FAILED"
	echo "$out" | tail -1
	exit 1
fi
echo "$out" | tail -1
