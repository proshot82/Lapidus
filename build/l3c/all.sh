#!/bin/bash
# build/l3c/all.sh файл.lua — метрики при своём (узком) правиле и при расширенных (d, e, wide), без кадров
f=$1
luajit build/l3c/ev.lua $f
for r in d e wide; do luajit build/l3c/ev.lua $f rule=$r quick | sed -n 2p; done
