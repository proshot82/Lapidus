#!/usr/bin/env python3
# build/l3c/mk.py ИМЯ "ряд1|ряд2|..." [LAP="{ {x,y}, ... }, head = N"] [SRC=x,y,сторона] [FX=x,y,сторона]
#                 [SOAP="x,y;x,y"] [STEP="x,y;x,y"] [LEN=2,5] [NOTE="замысел"]
# Черновик кандидата кв. 3 для проверки (правило видимого проигрыша берётся из build/l3c/vis.lua).
import sys
name, grid = sys.argv[1], sys.argv[2].split('|')
kv = dict(a.split('=', 1) for a in sys.argv[3:])
# буквы в сетке: S стояк, F мойка, p мыло (координаты берутся из сетки, клетка становится '.')
found = {'S': [], 'F': [], 'p': []}
for y, r in enumerate(grid):
    for x, ch in enumerate(r):
        if ch in found: found[ch].append('%d,%d' % (x + 1, y + 1))
grid = [r.replace('S', '.').replace('F', '.').replace('p', '.') for r in grid]
if found['p'] and 'SOAP' not in kv: kv['SOAP'] = ';'.join(found['p'])
W = len(grid[0])
assert all(len(r) == W for r in grid), [len(r) for r in grid]
def xy(s): return '{ %s }' % s
sd0 = kv.get('SRC', 'right')
fd0 = kv.get('FX', 'left')
if ',' in sd0: sx, sy, sd = sd0.split(',')
else: (sx, sy), sd = found['S'][0].split(','), sd0
if ',' in fd0: fx, fy, fd = fd0.split(',')
else: (fx, fy), fd = found['F'][0].split(','), fd0
soaps = ''.join('\n    { at = { %s }, kind = "porcelain", tag = "soap" },' % s for s in kv.get('SOAP', '3,4;5,7').split(';'))
step = ', '.join('{ %s }' % s for s in kv.get('STEP', '7,7').split(';'))
g = ',\n    '.join('"%s"' % r for r in grid)
open('build/l3c/%s.lua' % name, 'w', encoding='utf-8').write('''-- build/l3c/%s.lua — черновик кандидата кв. 3. %s
local STEP = { %s }
local lost = dofile("build/l3c/vis.lua").make(STEP, false)
return {
  step = STEP, lost = lost, visibleLoss = lost,
  id = 3, flat = 3, name = "Мыло", length = { %s }, pressure = 0, tile = "mustard",
  grid = {
    %s,
  },
  objects = {
    { at = { %s, %s }, kind = "source", ports = { %s = "V" } },
    { at = { %s, %s }, kind = "fixture", ports = { %s = "N" }, what = "sink" },%s
    { kind = "lapidus", cells = %s },
  },
  ablations = { { name = "без фаянса", remove = "soap" } },
}
''' % (name, kv.get('NOTE', ''), step, kv.get('LEN', '2, 5'), g, sx, sy, sd, fx, fy, fd, soaps,
       kv.get('LAP', '{ { 6, 7 }, { 7, 7 }, { 7, 6 }, { 6, 6 } }, head = 4')))
