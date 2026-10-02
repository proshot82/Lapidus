#!/bin/bash
# build/l9j/q.sh файл — раскладка + сжатые метрики + двери
cd /home/user/Lapidus
luajit build/l9j/show.lua "$1" | head -12
luajit build/l6b/check.lua "$1" 2>&1 | grep -v "^warning" | head -7
