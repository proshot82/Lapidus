#!/usr/bin/env python3
# build/l9j/mk.py имя "ряд1|ряд2|..." [TEE=x,y] [PLUG=x,y] [LAP="x,y;x,y;..."] [HEAD=1|n] [LEN=a,b] [NOTE=...]
# Кандидат кв. 9 на скелете «шахта»: колонка (7,2) вниз Н, стояк (7,8) вверх Н, тройник В-В + Н влево, заглушка В вправо.
import sys
name, grid = sys.argv[1], sys.argv[2].split('|')
kv = dict(a.split('=', 1) for a in sys.argv[3:])
W = len(grid[0])
assert all(len(r) == W for r in grid), [len(r) for r in grid]
lap = kv.get('LAP', '2,5;2,6;2,7').split(';')
cells = ', '.join('{ %s }' % c.replace(',', ', ') for c in lap)
head = kv.get('HEAD', 'n')
head = len(lap) if head == 'n' else int(head)
g = ',\n    '.join('"%s"' % r for r in grid)
src = kv.get('SRC', '7,8'); fx = kv.get('FX', '7,2')
open('build/l9j/%s.lua' % name, 'w', encoding='utf-8').write('''-- кв. 9, кандидат %s. %s
local okV, vis = pcall(dofile, "build/l9j/vis9.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "%s",
  length = { %s }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    %s,
  },
  objects = {
    { kind = "fixture", what = "heater", at = { %s }, ports = { down = "N" } },
    { kind = "source", at = { %s }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { %s }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { %s }, ports = { right = "V" } },
    { kind = "lapidus", cells = { %s }, head = %d },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
''' % (name, kv.get('NOTE', ''), name, kv.get('LEN', '3, 6').replace(',', ', '), g, fx.replace(',', ', '), src.replace(',', ', '),
       kv.get('TEE', '6,5').replace(',', ', '), kv.get('PLUG', '5,3').replace(',', ', '), cells, head))
