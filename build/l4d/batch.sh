#!/bin/bash
# build/l4d/batch.sh имя... — собрать и прогнать кандидатов, кратко (ворота + ширина по глубине).
cd /home/user/Lapidus
for n in "$@"; do
  python3 build/l4d/mk.py "$n" >/dev/null || continue
  echo "== $n"
  luajit build/l6b/check.lua build/l4d/$n.lua 2>&1 | grep -v "^warning" | head -6
done
