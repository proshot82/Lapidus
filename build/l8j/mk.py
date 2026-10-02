#!/usr/bin/env python3
# build/l8j/mk.py — раскладка из ASCII: F мойка, S стояк, A/B/C детали, P мыло, f ноги, o тело, H голова.
# Использование из Python: mk(name, rows, ports={'F':{'down':'N'},...}, L=(2,5), what={...}, note='...')
import sys
def mk(name, rows, ports, L=(2,5), what=None, note='', washOk=False, extra='', mustLift=None):
    what = what or {}
    H = len(rows); W = len(rows[0])
    grid = []; objs = []; lap = {}
    for y, r in enumerate(rows, 1):
        assert len(r) == W, (name, y, r)
        g = ''
        for x, ch in enumerate(r, 1):
            if ch in '#~': g += ch; continue
            g += '.'
            if ch == 'F': objs.append('{ kind = "fixture", what = "%s", at = { %d, %d }, ports = %s }' % (what.get('F','sink'), x, y, lua(ports['F'])))
            elif ch == 'S': objs.append('{ kind = "source", at = { %d, %d }, ports = %s }' % (x, y, lua(ports['S'])))
            elif ch in 'ABCD': objs.append('{ kind = "fitting", what = "%s", tag = "%s", at = { %d, %d }, ports = %s }' % (what.get(ch,'coupling'), ch, x, y, lua(ports[ch])))
            elif ch in 'PQ': objs.append('{ kind = "porcelain", tag = "soap%s", at = { %d, %d } }' % ('' if ch=='P' else '2', x, y))
            elif ch in 'fHo123456789': lap[(x,y)] = ch
        grid.append(g)
    # тело: от ноги f по соседям до головы H
    start = [c for c,v in lap.items() if v == 'f'][0]
    cells = [start]; seen = {start}
    while True:
        x, y = cells[-1]
        nxt = [c for c in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)] if c in lap and c not in seen]
        if not nxt: break
        # предпочесть 'o'/'H'
        cells.append(nxt[0]); seen.add(nxt[0])
    assert lap[cells[-1]] == 'H', (name, cells)
    body = ', '.join('{ %d, %d }' % c for c in cells)
    s = '''-- %s
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,%s%s
  id = 8, flat = 8, name = "%s",
  length = { %d, %d }, pressure = 0, tile = "mint",
  grid = {
%s
  },
  objects = {
%s
    { kind = "lapidus", cells = { %s }, head = %d },
  },
  ablations = {%s },
}
''' % (note, '\n  washOk = true,' if washOk else '', ('\n  mustLift = { %s },' % ', '.join('"%s"' % t for t in mustLift)) if mustLift else '', name, L[0], L[1], '\n'.join('    "%s",' % g for g in grid), '\n'.join('    %s,' % o for o in objs), body, len(cells), extra)
    open('/home/user/Lapidus/build/l8j/%s.lua' % name, 'w').write(s)
def lua(d): return '{ ' + ', '.join('%s = "%s"' % (k, v) for k, v in d.items()) + ' }'
