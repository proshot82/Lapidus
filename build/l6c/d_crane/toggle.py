#!/usr/bin/env python3
# toggle.py base.lua prefix — локальная доводка ядра: по одной переключить клетки стены/пустоты (кроме клеток объектов
# и стартового тела), прогнать метрики, напечатать лучшие по обезьяне среди решаемых с выигрышной конфигурацией 1.
import sys, re, subprocess, os
base = sys.argv[1]; prefix = sys.argv[2]
src = open(base, encoding='utf-8').read()
m = re.search(r'grid = \{\n(.*?)\n  \},', src, re.S)
rows = re.findall(r'"([^"]+)"', m.group(1))
H, W = len(rows), len(rows[0])
protect = set()
for x, y in re.findall(r'at = \{ (\d+), (\d+) \}', src): protect.add((int(x), int(y)))
lm = re.search(r'kind = "lapidus", cells = \{(.*?)\}, head', src, re.S)
for x, y in re.findall(r'\{ (\d+), (\d+) \}', lm.group(1)): protect.add((int(x), int(y)))
names = []
k = 0
for y in range(2, H):
    for x in range(2, W):
        if (x, y) in protect: continue
        r2 = [list(r) for r in rows]
        r2[y-1][x-1] = '.' if rows[y-1][x-1] == '#' else '#'
        g = ',\n    '.join('"%s"' % ''.join(r) for r in r2)
        new = src[:m.start(1)] + '    ' + g + ',' + src[m.end(1):]
        new = re.sub(r'grid = \{\n    (.*?),,', lambda mm: 'grid = {\n    ' + mm.group(1) + ',', new, flags=re.S)
        n = '%s_t%d_%d' % (prefix, x, y)
        open('/home/user/Lapidus/build/l6c/d_crane/%s.lua' % n, 'w', encoding='utf-8').write(new)
        names.append(n)
files = ['build/l6c/d_crane/%s.lua' % n for n in names]
out = subprocess.run(['luajit', 'build/l6c/d_crane/q.lua'] + files, cwd='/home/user/Lapidus', capture_output=True, text=True).stdout
res = []
cur = None
for line in out.splitlines():
    if not line.startswith('   '):
        cur = line
        nm = line.split(':')[0]
        mo = re.search(r'обезьяна ([\d.]+)%', line)
        ok = mo and 'вкфг 1' in line
        if not ok:
            try: os.remove('/home/user/Lapidus/build/l6c/d_crane/%s.lua' % nm)
            except: pass
        else: res.append((float(mo.group(1)), line))
res.sort()
for m_, l in res[:12]: print(l)
print('всего вариантов', len(names), 'решаемых с 1 выигрышной', len(res))
