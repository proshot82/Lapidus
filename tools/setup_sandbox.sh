#!/usr/bin/env bash
# Восстановление песочницы для «Лапидус. Ни капли».
#   bash tools/setup_sandbox.sh           — поставить недостающие программы (LÖVE 11.5, LuaJIT, rsvg, ImageMagick, ffmpeg, xvfb, zip)
#   bash tools/setup_sandbox.sh --vendor  — плюс скачать vendor/ (сборки LÖVE 11.5 и apktool) со сверкой SHA256; нужно для упаковки
set -e
cd "$(dirname "$0")/.."
need=()
for pair in love:love luajit:luajit rsvg-convert:librsvg2-bin convert:imagemagick ffmpeg:ffmpeg xvfb-run:xvfb zip:zip unzip:unzip; do
  bin=${pair%%:*}; pkg=${pair##*:}
  command -v "$bin" >/dev/null || need+=("$pkg")
done
if [ ${#need[@]} -gt 0 ]; then
  echo "ставлю: ${need[*]}"
  SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"
  $SUDO apt-get update -qq && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${need[@]}"
fi
# шрифты игры — в систему: без них rsvg подставляет широкий DejaVu и текст в арте вылезает за рамки
mkdir -p "$HOME/.local/share/fonts" && cp assets/fonts/*.ttf "$HOME/.local/share/fonts/" && fc-cache -f >/dev/null 2>&1 || true
fc-list | grep -q "PT Sans Narrow" || echo "ВНИМАНИЕ: шрифт PT Sans Narrow не виден rsvg — арт не пересобирать"
love --version | head -1
if [ "$1" = "--vendor" ]; then
  mkdir -p vendor && cd vendor
  base=https://github.com/love2d/love/releases/download/11.5
  for f in love-11.5-win64.zip love-11.5-android.apk love-11.5-apple-libraries.zip love-11.5-ios-source.zip; do
    [ -f "$f" ] || curl -fsSL -o "$f" "$base/$f"
  done
  [ -f apktool_2.9.3.jar ] || curl -fsSL -o apktool_2.9.3.jar https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar
  sha256sum -c SHA256SUMS.txt
fi
echo "песочница готова"
