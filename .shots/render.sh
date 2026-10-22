#!/usr/bin/env bash
# render.sh <out-prefix> <level> <spot>...   e.g. render.sh m4 res://levels/... "1240,-201" "2600,-222"
cd "$(dirname "$0")/.."
out=$1; lvl=$2; shift 2
spots=""
for s in "$@"; do spots="$spots [$s],"; done
echo "{\"level\": \"$lvl\", \"spots\": [${spots%,}], \"flags\": [\"m04_intro\", \"m09_approach\"]}" > .shots/tour.json
rm -f .shots/${out}*.png
n=$(( $# * 40 + 2 ))
flatpak run org.godotengine.Godot --path . --fixed-fps 60 --write-movie .shots/${out}.png --quit-after $n res://.shots/tour.tscn >/dev/null 2>&1
python3 - "$out" $# <<'PY'
import sys
from PIL import Image
out, n = sys.argv[1], int(sys.argv[2])
frames=[Image.open(f'.shots/{out}{i*40+39:08d}.png').convert('RGB') for i in range(n)]
sheet=Image.new('RGB',(640, 360*n))
for i,fr in enumerate(frames): sheet.paste(fr,(0,360*i))
sheet.save(f'.shots/{out}_sheet.png')
PY
