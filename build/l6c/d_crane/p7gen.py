#!/usr/bin/env python3
# p7gen.py — локальная доводка ядра P7: колонка с ниппелем над коридором; над муфтой труба (кран поднимает муфту,
# освобождая место для разворота), под ней карман с гнездом стояка (муфта падает туда, где её оставили).
import sys, subprocess
sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from mk import make

def level(name, dist, chim, pocket, left, right, cells, Lr=(3,5), up=2, srcside='right'):
    nx = 1 + left + 1          # столбец колонки
    kx = nx + dist             # столбец муфты
    W = kx + right + 2
    cy = max(up + 3, chim + 2)  # ряд коридора
    H = cy + pocket + 2
    g = [['#'] * W for _ in range(H)]
    def o(x, y): g[y-1][x-1] = '.'
    for x in range(2, W): o(x, cy)
    for y in range(cy - up, cy): o(nx, y)
    o(nx, cy - up - 1)
    for y in range(cy - chim, cy): o(kx, y)
    for y in range(cy + 1, cy + pocket + 1): o(kx, y)
    by = cy + pocket
    sx = kx + 1 if srcside == 'right' else kx - 1
    o(sx, by)
    rows = [''.join(r) for r in g]
    cport = 'right' if srcside == 'right' else 'left'
    sport = 'left' if srcside == 'right' else 'right'
    objs = ['{ kind = "fixture", what = "heater", at = { %d, %d }, ports = { down = "V" } }' % (nx, cy - up - 1),
            '{ kind = "source", at = { %d, %d }, ports = { %s = "N" } }' % (sx, by, sport),
            '{ kind = "fitting", what = "elbow", tag = "C", at = { %d, %d }, ports = { %s = "V", up = "V" } }' % (kx, cy - 1, cport),
            '{ kind = "fitting", what = "nipple", tag = "B", at = { %d, %d }, ports = { up = "N", down = "N" } }' % (nx, cy - 1)]
    cc = [(x + 0, cy) for x in cells]
    lap = "{ " + ", ".join("{ %d, %d }" % c for c in cc) + " }, head = %d" % len(cc)
    return make(name, rows, objs, lap, length=Lr, vis="visP.lua"), nx, kx

def run(names):
    files = ['build/l6c/d_crane/%s.lua' % n for n in names]
    out = subprocess.run(['luajit', 'build/l6c/d_crane/q.lua'] + files, cwd='/home/user/Lapidus', capture_output=True, text=True)
    return out.stdout + out.stderr

if __name__ == '__main__':
    names = []
    for dist in (2, 3):
        for chim in (2, 3):
            for left, right in ((1, 3), (2, 2)):
                nx = 1 + left + 1; kx = nx + dist
                # старт: голова над муфтой (у kx), ноги слева; длина 5 (или 4 для dist=2)
                for ori in ('Hright', 'Hleft'):
                    L = 5
                    xs = list(range(kx - L + 1, kx + 1))
                    if xs[0] < 2: continue
                    if nx not in xs: continue
                    cells = xs if ori == 'Hright' else list(reversed(xs))
                    n = 'pt_d%d_c%d_l%d_%s' % (dist, chim, left, ori)
                    level(n, dist, chim, 2, left, right, cells)
                    names.append(n)
    print(run(names))
