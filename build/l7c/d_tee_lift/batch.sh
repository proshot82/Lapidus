#!/bin/bash
# batch.sh файл... — параллельный прогон ev.lua (по 4 сразу), итоги — в build/l7c/d_tee_lift/z/out/<имя>.txt
mkdir -p build/l7c/d_tee_lift/z/out
for f in "$@"; do
  n=$(basename "$f" .lua)
  ( timeout 1500 luajit build/l7c/d_tee_lift/ev.lua "$f" pic 8 > build/l7c/d_tee_lift/z/out/$n.txt 2>&1;
    luajit build/l7c/d_tee_lift/wins.lua "$f" 2>/dev/null | head -3 >> build/l7c/d_tee_lift/z/out/$n.txt ) &
  while [ $(jobs -r | wc -l) -ge 4 ]; do sleep 1; done
done
wait
echo ГОТОВО
