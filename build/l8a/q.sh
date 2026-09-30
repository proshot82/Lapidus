#!/bin/bash
# build/l8a/q.sh файл.lua — быстрый прогон: сводка ворот (batch -q), нужен ли брандспойт, топ классов скрытых/видимых.
f=$1
luajit build/l8a/batch.lua -q "$f" | cut -c1-330
luajit build/l8a/hose.lua "$f"
luajit build/l8a/cls.lua "$f" ${2:-6} 2>/dev/null | head -30
