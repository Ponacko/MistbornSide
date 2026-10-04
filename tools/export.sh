#!/usr/bin/env bash
# Exports desktop builds into build/. Needs the Godot 4.7 export templates
# for this Godot version installed (Editor > Manage Export Templates).
#   tools/export.sh            # Linux and Windows
#   tools/export.sh Linux      # one preset
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-flatpak run org.godotengine.Godot}"
presets=("${@:-Linux}")
[ $# -eq 0 ] && presets=("Linux" "Windows Desktop")
for p in "${presets[@]}"; do
	case "$p" in
		Linux) out="build/linux/MistbornSide.x86_64" ;;
		"Windows Desktop") out="build/windows/MistbornSide.exe" ;;
		*) echo "unknown preset $p"; exit 1 ;;
	esac
	mkdir -p "$(dirname "$out")"
	$GODOT --headless --path . --export-release "$p" "$out"
	echo "exported $out"
done
