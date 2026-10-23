#!/usr/bin/env python3
# build/p6/neck/gen_c.py — семейство «b» с комнатой 2×2 (Lmin 3) или 2×3 (Lmin 4), перебор старта и раскладки пары.
import os
out = 'build/p6/neck/gen2'
os.makedirs(out, exist_ok=True)
def build(rw, lc, elbx, cplx, start, lmin):
    cx = 3
    sx = cx + rw + lc           # шахта
    W = sx + 3; H = 6
    g = [['#'] * W for _ in range(H)]
    for x in range(cx, sx + 1): g[1][x - 1] = '.'
    g[1][sx] = '.'                                   # клетка прибора
    g[2][cx - 1] = '.'
    for x in range(cx, cx + rw): g[3][x - 1] = '.'
    for x in range(cx - 1, sx + 1): g[4][x - 1] = '.'
    for y in (3, 4): g[y - 1][sx - 1] = '.'
    L = 3 + (sx - 1 - cx)
    if L > 6 or L < lmin: return
    if not (cx < elbx < cplx < sx): return
    starts = {
        'shaft': [(sx, 2), (sx, 3), (sx, 4), (sx, 5)], 'shaftH': None,
        'room': [(cx, 4), (cx + 1, 4), (cx + 1, 5), (cx + 2, 5)],
        'low': [(sx - 3, 5), (sx - 2, 5), (sx - 1, 5), (sx, 5)],
    }
    cells = starts[start]
    if cells is None: return
    cells = cells[:max(lmin, 4)]
    for (x, y) in cells:
        if g[y - 1][x - 1] != '.': return
    head = len(cells) if start == 'shaft' else 1
    lap = '{ ' + ', '.join('{ %d, %d }' % c for c in cells) + ' }, head = %d' % head
    rows = ',\n    '.join('"%s"' % ''.join(r) for r in g)
    name = 'r%d_lc%d_e%d_c%d_%s' % (rw, lc, elbx, cplx, start)
    open(os.path.join(out, name + '.lua'), 'w').write('''return {
  id = 72, flat = 6, name = "%s", length = { %d, %d }, pressure = 0, tile = "mint",
  grid = {
    %s,
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { %d, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { %d, 2 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { %d, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = %s },
  },
}
''' % (name, lmin, L, rows, sx + 1, elbx, cplx, lap))
for rw, lmin in ((2, 3), (3, 4)):
    for lc in (1, 2, 3):
        for elbx in range(4, 9):
            for cplx in range(5, 10):
                for start in ('shaft', 'room', 'low'):
                    build(rw, lc, elbx, cplx, start, lmin)
