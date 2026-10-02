#!/bin/bash
# build/l7f/run.sh имя… — check.lua по кандидату build/l7f/c/имя.lua → build/l7f/out/имя.txt (первые строки в терминал)
cd /home/user/Lapidus
for n in "$@"; do
  luajit build/l6b/check.lua build/l7f/c/$n.lua > build/l7f/out/$n.txt 2>&1
  echo "== $n"; grep -v "^warning" build/l7f/out/$n.txt | head -7
done
