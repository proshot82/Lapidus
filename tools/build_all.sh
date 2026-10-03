#!/usr/bin/env bash
# Сборка «Лапидус. Ни капли» для всех платформ → build/dist:
#   Lapidus.love                 — для LÖVE 11.5 (Linux, Steam Deck, любой ПК с LÖVE);
#   Lapidus_win64_portable.zip   — Windows: склеенный Lapidus.exe + DLL LÖVE, распаковать и запустить;
#   Lapidus.apk                  — Android: официальный love-11.5-android.apk с игрой внутри, своё имя пакета, подпись;
#   lapidus_web.zip              — веб (love.js) для GitHub Pages / Telegram Mini App (tools/build_web.sh).
# Нужно: bash tools/setup_sandbox.sh --vendor (сборки LÖVE и apktool со сверкой SHA256), java.
# Ключ подписи Android: LAP_KEYSTORE (по умолчанию build/keys/lapidus.jks) и LAP_KS_PASS; если ключа нет — создаётся новый.
# ВАЖНО: ключ в репозиторий не кладётся (репозиторий публичный). Обновления APK ставятся поверх только с тем же ключом.
set -e
cd "$(dirname "$0")/.."
D=build/dist
mkdir -p "$D" build/keys
rm -f "$D/Lapidus.love" "$D/Lapidus_win64_portable.zip" "$D/Lapidus.apk"

# 0. картинки — 8 бит на канал: в браузере (WebGL) rgba16 не открывается и игра не рисуется
bad=$(for f in assets/gfx/*.png; do [ "$(identify -format '%z' "$f[0]")" = 8 ] || echo "$f"; done)
[ -z "$bad" ] || { echo "16-битные PNG (пересохранить с -depth 8): $bad"; exit 1; }

# 1. .love
zip -qr "$D/Lapidus.love" main.lua conf.lua core game util levels assets puzzles/solutions.json -x "levels/_format_example.lua"
echo "love: $(du -h "$D/Lapidus.love" | cut -f1)"

# 2. Windows: love.exe + игра = Lapidus.exe (официальный способ fused), рядом DLL и лицензия
W=build/dist/_win && rm -rf "$W" && mkdir -p "$W"
unzip -q vendor/love-11.5-win64.zip -d "$W"
L=$(ls -d "$W"/love-11.5-win64)
mkdir -p "$W/Lapidus"
cat "$L/love.exe" "$D/Lapidus.love" > "$W/Lapidus/Lapidus.exe"
cp "$L"/*.dll "$L/license.txt" "$W/Lapidus/"
(cd "$W" && zip -qr "../Lapidus_win64_portable.zip" Lapidus)
rm -rf "$W"
echo "win64: $(du -h "$D/Lapidus_win64_portable.zip" | cut -f1)"

# 3. Android
A=build/dist/_apk && rm -rf "$A" && mkdir -p "$A"
java -jar vendor/apktool_2.9.3.jar d -f -s -o "$A/dec" vendor/love-11.5-android.apk >/dev/null
mkdir -p "$A/dec/assets" && cp "$D/Lapidus.love" "$A/dec/assets/game.love"
python3 - "$A/dec" << 'PY'
import re, sys
d = sys.argv[1]
m = open(d + '/AndroidManifest.xml', encoding='utf-8').read()
m = m.replace('android:label="LÖVE for Android"', 'android:label="Лапидус"')
for perm in ('RECORD_AUDIO', 'BLUETOOTH', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE'):   # игре не нужны
    m = re.sub(r'\s*<uses-permission[^>]*android\.permission\.%s"/>' % perm, '', m)
# игра встроена: убрать открытие чужих .love и загрузчик
m = re.sub(r'\s*<intent-filter>\s*<action android:name="android.intent.action.VIEW"/>.*?</intent-filter>', '', m, flags=re.S)
m = re.sub(r'\s*<activity android:exported="true" android:name="org.love2d.android.DownloadActivity".*?</activity>', '', m, flags=re.S)
m = re.sub(r'\s*<service android:name="org.love2d.android.DownloadService"/>', '', m)
open(d + '/AndroidManifest.xml', 'w', encoding='utf-8').write(m)
b = open(d + '/res/values/bools.xml', encoding='utf-8').read()   # игра встроена в assets/game.love; экрана выбора игр нет
b = b.replace('<bool name="embed">false</bool>', '<bool name="embed">true</bool>')
assert '<bool name="embed">true</bool>' in b and '<bool name="selector_active">false</bool>' in b
open(d + '/res/values/bools.xml', 'w', encoding='utf-8').write(b)
v = d + '/res/values-v19/bools.xml'                               # на Android 4.4+ экран выбора игр включён отдельно
t = open(v, encoding='utf-8').read().replace('<bool name="selector_active">true</bool>', '<bool name="selector_active">false</bool>')
open(v, 'w', encoding='utf-8').write(t)
y = open(d + '/apktool.yml', encoding='utf-8').read()
y = y.replace('renameManifestPackage: null', 'renameManifestPackage: io.github.proshot82.lapidus')
y = re.sub(r'versionCode: \d+', 'versionCode: 1', y).replace('versionName: 11.5a', 'versionName: 1.0')
open(d + '/apktool.yml', 'w', encoding='utf-8').write(y)
PY
for p in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  convert build/dist/icon512.png -resize "${p#*:}x${p#*:}" "$A/dec/res/drawable-${p%%:*}/love.png"
done
java -jar vendor/apktool_2.9.3.jar b -o "$A/unsigned.apk" "$A/dec" >/dev/null
KS=${LAP_KEYSTORE:-build/keys/lapidus.jks}
if [ ! -f "$KS" ]; then
  PASS=${LAP_KS_PASS:-$(head -c 18 /dev/urandom | base64 | tr -d '/+=')}
  keytool -genkeypair -keystore "$KS" -alias lapidus -keyalg RSA -keysize 2048 -validity 10000 -storepass "$PASS" -keypass "$PASS" \
    -dname "CN=Lapidus, O=Lapidus Ni Kapli" >/dev/null 2>&1
  echo "$PASS" > build/keys/PASSWORD.txt
  echo "СОЗДАН НОВЫЙ КЛЮЧ: $KS (пароль — build/keys/PASSWORD.txt). Сохраните оба файла: без них обновление не встанет поверх."
fi
PASS=${LAP_KS_PASS:-$(cat build/keys/PASSWORD.txt)}
[ -f build/dist/uber-apk-signer.jar ] || curl -fsSL -o build/dist/uber-apk-signer.jar \
  https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar
java -jar build/dist/uber-apk-signer.jar -a "$A/unsigned.apk" --ks "$KS" --ksAlias lapidus --ksPass "$PASS" --ksKeyPass "$PASS" \
  -o "$A/signed" >/dev/null
cp "$A"/signed/*-aligned-signed.apk "$D/Lapidus.apk"
rm -rf "$A"
echo "android: $(du -h "$D/Lapidus.apk" | cut -f1)"

# 4. Веб
if [ "$1" != "--no-web" ]; then
  bash tools/build_web.sh >/dev/null && cp build/web/lapidus_web.zip "$D/" && echo "web: $(du -h "$D/lapidus_web.zip" | cut -f1)"
fi
ls -la "$D"
