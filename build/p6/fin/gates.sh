#!/bin/bash
# сводка ворот по файлам: bash build/p6/fin/gates.sh файл...
cd /home/user/Lapidus
for f in "$@"; do
  out=$(timeout 600 luajit build/l6b/check.lua "$f" 2>&1)
  mv=$(echo "$out" | grep -o 'ходов [0-9]*' | head -1 | cut -d' ' -f2)
  hid=$(echo "$out" | grep -o 'СКРЫТЫХ [0-9]*' | cut -d' ' -f2)
  sm=$(echo "$out" | grep -o 'ОБЕЗЬЯНА [0-9.]*' | cut -d' ' -f2)
  dp=$(echo "$out" | grep -o 'ГЛУБИНА [0-9]*' | cut -d' ' -f2)
  nb=$(echo "$out" | grep -o 'наобум [0-9.]*' | cut -d' ' -f2)
  wd=$(echo "$out" | grep -o 'ширина [0-9]*' | cut -d' ' -f2)
  wk=$(echo "$out" | grep -o 'прогулка max [0-9]*' | cut -d' ' -f3)
  dr=$(echo "$out" | grep -o 'ДВЕРИ в скрытые с пути: [^(]*' | cut -d: -f2-)
  hv=$(echo "$out" | grep -o 'дверями: [0-9]* в первой половине, [0-9]* во второй' | grep -o '[0-9]*' | tr '\n' '/')
  st=$(echo "$out" | grep -o 'состояний [0-9]*' | head -1 | cut -d' ' -f2)
  echo "$(basename $f) ход=$mv сост=$st скр=$hid обез=$sm наоб=$nb шир=$wd глуб=$dp прог=$wk двери=[$dr] половины=$hv"
done
