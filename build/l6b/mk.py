#!/usr/bin/env python3
# build/l6b/mk.py имя "ряд1|ряд2|..." [LAP=...] [SRC=x,y] [FX=x,y] [CP=x,y] [NIP=x,y] [LEN=a,b] [EXTRA=...]
import sys
name, grid = sys.argv[1], sys.argv[2].split('|')
kv = dict(a.split('=', 1) for a in sys.argv[3:])
lap = kv.get('LAP', '{ { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3')
g = ',\n    '.join('"%s"' % r for r in grid)
open('build/l6b/%s.lua' % name, 'w', encoding='utf-8').write('''return {
  visibleLoss = dofile("build/l6b/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { %s }, pressure = 0, tile = "mustard",
  grid = {
    %s,
  },
  objects = {
    { kind = "source", at = { %s }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { %s }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { %s }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { %s }, ports = { up = "N", down = "N" } },%s
    { kind = "lapidus", cells = %s },
  },
}
''' % (kv.get('LEN', '3, 5'), g, kv.get('SRC', '2, 5'), kv.get('FX', '7, 2'), kv.get('CP', '7, 5'), kv.get('NIP', '7, 4'), kv.get('EXTRA', ''), lap))
