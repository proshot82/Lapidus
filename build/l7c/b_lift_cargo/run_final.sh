#!/bin/bash
# финальные проверки кандидата: официальный check.lua (свой и широкий видимый проигрыш), verify.lua, метрики §7
cd /home/user/Lapidus
B=build/l7c/b_lift_cargo
N=${1:-x2}
luajit build/l6b/check.lua $B/$N.lua > $B/out_check_$N.txt 2>&1 &
luajit build/l6b/check.lua $B/${N}w.lua > $B/out_check_${N}w.txt 2>&1 &
luajit $B/verify.lua $B/$N.lua > $B/out_verify_$N.txt 2>&1 &
luajit $B/analyze.lua $B/$N.lua > $B/out_analyze_$N.txt 2>&1 &
wait
echo done
