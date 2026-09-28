#!/bin/bash
# mkv.sh имя "описание деталей" < карта ; вид. проигрыш — строка VIS (lua-выражение, по умолчанию V.vis)
name=$1; shift
spec=$(cat)
printf '%s\n\n%s\n' "$spec" "$*" | python3 /home/user/Lapidus/build/l6c/b_wall_forever/gen.py $name > /dev/null
