#!/bin/bash
# run.sh файл.lua — gates + path traps
cd /home/user/Lapidus
timeout 250 luajit build/l6c/b_wall_forever/mycheck.lua "$1" 2>&1 | iconv -f utf-8 -t utf-8 -c
[ "$2" = "p" ] && timeout 100 luajit build/l6c/b_wall_forever/ptraps.lua "$1"
[ "$2" = "f" ] && timeout 100 luajit build/l6c/b_wall_forever/mycheck.lua "$1" frames | tail -n +6
exit 0
