#!/usr/bin/env bash
# Runs the headless test suite. Optional argument: a filename filter.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-flatpak run org.godotengine.Godot}"
tools/check.sh >/dev/null || { tools/check.sh; exit 1; }
$GODOT --headless --path . --fixed-fps 60 -s tests/run.gd -- "$@"
