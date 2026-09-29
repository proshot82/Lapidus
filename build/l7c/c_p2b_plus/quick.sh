#!/bin/bash
# quick.sh эскиз — ворота одной строкой (с разметкой fvis), соседи пути, перепись живых и скрытых (вывод инструмента).
f=$1; b=$(basename $f .lua); d=$(dirname $f)
h=$d/${b}h.lua
[ -f $h ] || printf 'local V = dofile("build/l7c/c_p2b_plus/fvis.lua")\nlocal d = dofile("%s")\nd.visibleLoss = V.make(d)\nreturn d\n' "$f" > $h
luajit build/l7c/c_p2b_plus/ev.lua $h
luajit build/l7c/c_p2b_plus/adj.lua $h 2>&1 | head -3
n=$d/${b}n.lua
[ -f $n ] || printf 'local V = dofile("build/l7c/c_p2b_plus/nvis.lua")\nlocal d = dofile("%s")\nd.visibleLoss = V.make(d)\nreturn d\n' "$f" > $n
luajit build/l7c/c_p2b_plus/ev.lua $n
luajit build/l7c/c_p2b_plus/adj.lua $n 2>&1 | head -3
[ -z "$2" ] || luajit build/l7c/c_p2b_plus/lsig.lua $h $2
[ -z "$3" ] || luajit build/l7c/c_p2b_plus/sig.lua $h $3
