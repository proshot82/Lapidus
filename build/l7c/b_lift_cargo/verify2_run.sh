#!/bin/bash
# verify2_run.sh — все замеры второй проверки скептика (p2b) с записью в verify2_out_*.txt. Решений не печатает.
cd /home/user/Lapidus
B=build/l7c/b_lift_cargo
luajit build/l6b/check.lua $B/verify2_p2b.lua > $B/verify2_out_check_honest.txt 2>&1 &
luajit build/l6b/check.lua $B/verify2_p2b_noN.lua > $B/verify2_out_check_honestN.txt 2>&1 &
luajit $B/verify2_census.lua $B/p2b.lua > $B/verify2_out_census.txt 2>&1 &
wait
luajit $B/verify2_claims.lua $B/p2b.lua > $B/verify2_out_claims.txt 2>&1 &
luajit build/l6b/fate.lua $B/verify2_p2b.lua > $B/verify2_out_fate_honest.txt 2>&1 &
luajit $B/verify2_census.lua $B/verify2_noadp.lua > $B/verify2_out_noadp.txt 2>&1 &
wait
luajit $B/verify2_abl.lua $B/p2b.lua > $B/verify2_out_abl.txt 2>&1 &
luajit $B/verify2_engine.lua $B/p2b.lua > $B/verify2_out_engine.txt 2>&1 &
luajit build/l6b/check.lua $B/verify2_noadp.lua > $B/verify2_out_check_noadp.txt 2>&1 &
wait
echo done
