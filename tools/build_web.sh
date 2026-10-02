#!/usr/bin/env bash
# Веб-сборка «Лапидус. Ни капли»: game.love → love.js (LÖVE 11.5, режим совместимости -c) → плоская папка build/web/site
# и архив build/web/lapidus_web.zip для GitHub Pages / Telegram Mini App.
# Нужен npm-пакет love.js с GitHub (в ~/webtools115): npm i github:Davidobot/love.js  (в npm лежит только 11.4).
set -e
cd "$(dirname "$0")/.."
TOOLS=${LOVEJS_DIR:-/home/claude/webtools115}
[ -d "$TOOLS/node_modules/love.js" ] || { mkdir -p "$TOOLS" && cd "$TOOLS" && npm init -y >/dev/null && npm i github:Davidobot/love.js && cd -; }
mkdir -p build/web && rm -f build/web/game.love && rm -rf build/web/out build/web/site
zip -qr build/web/game.love main.lua conf.lua core game util levels assets puzzles/solutions.json -x "levels/_format_example.lua"
(cd "$TOOLS" && npx love.js -c -t "Лапидус. Ни капли" -m 134217728 "$OLDPWD/build/web/game.love" "$OLDPWD/build/web/out")
mkdir -p build/web/site
cp build/web/out/game.js build/web/out/game.data build/web/out/love.wasm build/web/site/
# сборка love.js держит FS внутри модуля; для сохранений в IndexedDB экспортируем FS и IDBFS наружу
python3 - << 'PY'
p = 'build/web/out/love.js'
s = open(p, encoding='utf-8').read()
old = 'FS.staticInit();Module["FS_createFolder"]'
assert s.count(old) == 1, 'love.js: точка экспорта FS не найдена'
s = s.replace(old, 'FS.staticInit();Module["FS"]=FS;Module["IDBFS"]=IDBFS;Module["FS_createFolder"]')
open('build/web/site/love.js', 'w', encoding='utf-8').write(s)
PY
cp tools/web/index.html build/web/site/index.html
(cd build/web/site && rm -f ../lapidus_web.zip && zip -q ../lapidus_web.zip index.html game.js game.data love.js love.wasm)
ls -la build/web/site build/web/lapidus_web.zip
