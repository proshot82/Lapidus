#!/usr/bin/env python3
# batch.py — пачка вариантов ручного ядра (локальная доводка): python3 batch.py <модуль-с-V> ; пишет файлы и печатает метрики
import sys, subprocess, importlib
sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from mk import build
mod = importlib.import_module(sys.argv[1])
names = []
for n, spec in mod.V.items():
    m = spec['map']; kw = {k: v for k, v in spec.items() if k not in ('map', 'O')}
    build(n, m, spec.get('O', mod.O), None, **kw)
    names.append(n)
files = ['build/l6c/d_crane/%s.lua' % n for n in names]
env = dict(__import__('os').environ)
if len(sys.argv) > 2: env['NOSTRICT'] = '1'
out = subprocess.run(['luajit', 'build/l6c/d_crane/q.lua'] + files, cwd='/home/user/Lapidus', capture_output=True, text=True, env=env)
print(out.stdout + out.stderr)
