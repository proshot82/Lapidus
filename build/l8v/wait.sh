#!/bin/bash
# build/l8v/wait.sh префикс семена… — ждать строки «=== seed» во всех файлах build/l8v/out/<префикс>_<семя>.txt
p=$1; shift
ok=0
while [ $ok -eq 0 ]; do
  ok=1
  for s in "$@"; do grep -q "^=== seed" build/l8v/out/${p}_$s.txt 2>/dev/null || ok=0; done
  [ $ok -eq 0 ] && sleep 20
done
echo "$p готовы"; tail -n 1 build/l8v/out/${p}_*.txt
