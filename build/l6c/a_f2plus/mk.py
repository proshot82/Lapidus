#!/usr/bin/env python3
# build/l6c/a_f2plus/mk.py имя 'ряд1|ряд2|...' 'объекты' [LEN=3,5] [NOTE=...] [VIS=vis.lua] [ABL=...]
# объекты: через ';' — S x,y dir=T | F x,y dir=T | C x,y (муфта В/В гориз.) | N x,y (ниппель Н/Н верт.)
#          | T x,y dir=T (глухой отвод) | L x,y x,y x,y ... (клетки от ног к голове)
import sys
name, grid, objs = sys.argv[1], sys.argv[2].split('|'), sys.argv[3]
kv = dict(a.split('=', 1) for a in sys.argv[4:])
out = []
tags = {}
for o in objs.split(';'):
    o = o.strip().split()
    k = o[0]
    if k == 'L':
        cells = ', '.join('{ %s }' % c for c in o[1:])
        lap = '{ kind = "lapidus", cells = { %s }, head = %d },' % (cells, len(o) - 1)
        continue
    x, y = o[1].split(',')
    ports = {}
    for p in o[2:]:
        d, t = p.split('=')
        ports[{'u': 'up', 'd': 'down', 'l': 'left', 'r': 'right'}[d]] = t
    ps = ', '.join('%s = "%s"' % (d, t) for d, t in ports.items())
    if k == 'S': out.append('{ kind = "source", at = { %s, %s }, ports = { %s } },' % (x, y, ps))
    elif k == 'F': out.append('{ kind = "fixture", what = "heater", at = { %s, %s }, ports = { %s } },' % (x, y, ps))
    elif k == 'T': out.append('{ kind = "stub", tag = "hook", at = { %s, %s }, ports = { %s } },' % (x, y, ps))
    elif k == 'C': out.append('{ kind = "fitting", what = "coupling", tag = "cpl", at = { %s, %s }, ports = { %s } },' % (x, y, ps or 'left = "V", right = "V"'))
    elif k == 'N': out.append('{ kind = "fitting", what = "nipple", tag = "nip", at = { %s, %s }, ports = { %s } },' % (x, y, ps or 'up = "N", down = "N"'))
    elif k == 'E': out.append('{ kind = "fitting", what = "elbow", tag = "elb", at = { %s, %s }, ports = { %s } },' % (x, y, ps))
out.append(lap)
g = ',\n    '.join('"%s"' % r for r in grid)
note = kv.get('NOTE', '')
vis = kv.get('VIS', 'build/l6c/a_f2plus/vis.lua')
abl = kv.get('ABL', 'dofile("build/l6c/a_f2plus/abl.lua")')
open('build/l6c/a_f2plus/%s.lua' % name, 'w', encoding='utf-8').write('''-- %s: %s
return {
  visibleLoss = dofile("%s"),
  id = 6, flat = 6, name = "Намертво", length = { %s }, pressure = 0, tile = "mustard",
  grid = {
    %s,
  },
  objects = {
    %s
  },
  ablations = %s,
}
''' % (name, note, vis, kv.get('LEN', '3, 5'), g, '\n    '.join(out), abl))
print('build/l6c/a_f2plus/%s.lua' % name)
