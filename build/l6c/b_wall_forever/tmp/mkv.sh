#!/bin/bash
# mkv.sh имя "описание деталей" [ОПЦИЯ=...]... < карта
name=$1; shift
spec=$(cat)
{ printf '%s\n\n' "$spec"; for a in "$@"; do printf '%s\n' "$a"; done; } | python3 /home/user/Lapidus/build/l6c/b_wall_forever/gen.py $name > /dev/null
