#!/bin/bash
# build/l7e/run.sh имя [frames] — check.lua по кандидату build/l7e/c/имя.lua, вывод в build/l7e/out/имя.txt
cd /home/user/Lapidus
for n in "$@"; do
  [ "$n" = frames ] && continue
  luajit build/l6b/check.lua build/l7e/c/$n.lua ${FR} > build/l7e/out/$n.txt 2>&1
  echo "== $n"; grep -v "^warning" build/l7e/out/$n.txt | head -7
done
