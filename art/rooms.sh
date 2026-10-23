#!/bin/bash
# Фоны квартир из Blender: art/rooms.sh [номера…] (без номеров — все). ~1 мин на квартиру.
# room_prep.py (плоские слои и геометрия) → art/blender/room.py (рендер) → assets/gfx/lvlNN.jpg
set -e
cd "$(dirname "$0")/.."
IDS="${*:-1 2 3 4 5 6 7 8 9 10}"
python3 art/room_prep.py $IDS
for i in $IDS; do
  p=$(printf "lvl%02d" "$i")
  xvfb-run -a blender -b -P art/blender/room.py -- "build/room/$p.json" "build/room/${p}_render.png" 2>&1 | grep -E "ROOM|Error" || true
  convert "build/room/${p}_render.png" -quality 88 "assets/gfx/$p.jpg"
done
