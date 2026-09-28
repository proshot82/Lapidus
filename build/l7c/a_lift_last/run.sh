#!/bin/bash
# run.sh a15 a16 ... — прогнать check.lua по кандидатам параллельно (≤4), вывод в out_<имя>.txt
cd /home/user/Lapidus
for n in "$@"; do
  ( timeout 900 luajit build/l6b/check.lua build/l7c/a_lift_last/$n.lua > build/l7c/a_lift_last/out_$n.txt 2>&1 ) &
  while [ $(jobs -r | wc -l) -ge 4 ]; do sleep 1; done
done
wait
for n in "$@"; do echo "== $n"; grep -v "^warning" build/l7c/a_lift_last/out_$n.txt | head -5; done
