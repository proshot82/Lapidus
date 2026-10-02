#!/bin/bash
# build/l7d/run.sh имя [frames] — check.lua по кандидату build/l7d/c/имя.lua, вывод в build/l7d/out/имя.txt
cd /home/user/Lapidus
mkdir -p build/l7d/out
luajit build/l6b/check.lua build/l7d/c/$1.lua $2 > build/l7d/out/$1.txt 2>&1
echo "== $1"; grep -v "^warning" build/l7d/out/$1.txt | head -8
