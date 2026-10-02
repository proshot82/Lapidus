#!/bin/bash
# mkic.sh имя "sx sy hx lowY" "описание деталей" [ОПЦИЯ=...]... < карта  — вариант с vis_ic
name=$1; shift; args=$1; shift
spec=$(cat)
{ printf '%s\n\n' "$spec"; for a in "$@"; do printf '%s\n' "$a"; done; } | python3 /home/user/Lapidus/build/l6c/b_wall_forever/gen.py $name > /dev/null
set -- $args
sed -i "s#^local V = dofile(\"build/l6c/b_wall_forever/vis.lua\")#local V = { vis = dofile(\"build/l6c/b_wall_forever/vis_ic.lua\")($1, $2, $3, $4) }#" $name.lua
