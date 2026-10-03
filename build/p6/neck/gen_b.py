#!/usr/bin/env python3
# build/p6/neck/gen_b.py — варианты семейства «b» (колодец-разворот + цепочка угольник/муфта) для перебора параметров.
import itertools, os, sys
out = 'build/p6/neck/gen'
def build(lc, gap, extra, start, lmaxplus, nub):
    # координаты: колодец x=3..4, ряды 4..5; стояк (2,5); дымоход (3,3); верхний коридор ряд 2
    cx = 3
    sx = cx + 2 + lc            # шахта
    W = sx + 3
    H = 6
    g = [['#'] * W for _ in range(H)]
    for x in range(cx, sx + 1): g[1][x - 1] = '.'          # верхний коридор (3..sx, 2)
    g[2][cx - 1] = '.'                                      # дымоход
    g[3][cx - 1] = '.'; g[3][cx] = '.'                      # колодец верх
    for x in range(cx - 1, sx + 1): g[4][x - 1] = '.'       # низ: стояк-клетка, колодец низ, нижний коридор
    for y in (3, 4): g[y - 1][sx - 1] = '.'                 # шахта
    g[1][sx] = '.'                                          # клетка прибора (sx+1,2)
    for (x, y) in nub: g[y - 1][x - 1] = '.'
    L = 2 + (sx - 1 - cx) + 1  # голова (3,4),(3,3),(3,2),(4,2)..(sx-1,2)
    elb = (cx + 1, 2)
    cpl = (cx + 2 + gap, 2)
    if cpl[0] >= sx: return None
    starts = {
        'room': '{ { 3, 4 }, { 4, 4 }, { 4, 5 }, { 5, 5 } }, head = 1',
        'shaft': '{ { %d, 2 }, { %d, 3 }, { %d, 4 }, { %d, 5 } }, head = 4' % (sx, sx, sx, sx),
        'low': '{ { %d, 5 }, { %d, 5 }, { %d, 5 } }, head = 1' % (sx - 2, sx - 1, sx),
        'room3': '{ { 4, 4 }, { 4, 5 }, { 5, 5 } }, head = 1',
    }
    lap = starts[start]
    rows = ',\n    '.join('"%s"' % ''.join(r) for r in g)
    name = 'b_lc%d_g%d_%s_p%d%s' % (lc, gap, start, lmaxplus, ('_n' + ''.join('%d%d' % p for p in nub)) if nub else '')
    txt = '''return {
  id = 69, flat = 6, name = "%s", length = { 3, %d }, pressure = 0, tile = "mint",
  grid = {
    %s,
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { %d, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { %d, %d }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { %d, %d }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = %s },
  },
}
''' % (name, L + lmaxplus, rows, sx + 1, elb[0], elb[1], cpl[0], cpl[1], lap)
    open(os.path.join(out, name + '.lua'), 'w').write(txt)
    return name
for lc in (1, 2, 3):
    for gap in (0, 1):
        for start in ('room', 'shaft', 'low', 'room3'):
            for lp in (0, 1):
                for nub in ([], [(6, 3)]):
                    build(lc, gap, None, start, lp, nub)
