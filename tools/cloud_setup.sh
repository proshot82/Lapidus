#!/bin/bash
# Текст для поля «Setup script» облачного окружения Claude Code (claude.ai/code → значок облака → настройки окружения).
# Ставит программы для игры один раз; дальше окружение кэшируется. Ошибки не валят запуск сессии.
apt-get update -qq || true
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq love luajit librsvg2-bin imagemagick ffmpeg xvfb zip unzip || true
