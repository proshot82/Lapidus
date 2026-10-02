#!/usr/bin/env python3
# pgen.py — локальная доводка ядра P: короткая колонка с ниппелем над коридором, муфта в трубе над карманом со стояком.
# Замысел: развернуться можно только в кармане под муфтой и только пока она лежит на Лапидусе; муфта падает туда,
# где её оставили, и закрывает карман намертво. Печатает метрики (без решений).
import sys, subprocess
sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from mk import make

def level(name, nx, kx, W, up=2, pocket=2, cells=None, Lr=(3,5), chim=1, leftwall=1, srcside='right'):
    # коридор ряд cy; колонка над nx: ниппель в (nx, cy-1), колонка на (nx, cy-up-1)
    cy = up + 3 + max(0, chim - 1)
    H = cy + pocket + 2
    g = [['#'] * W for _ in range(H)]
    def o(x, y): g[y-1][x-1] = '.'
    for x in range(1 + leftwall, W): o(x, cy)
    for y in range(cy - up, cy): o(nx, y)          # клетки колонны: ниппель и финал ниппеля
    o(nx, cy - up - 1)                              # колонка
    for y in range(cy - chim, cy): o(kx, y)         # труба муфты
    for y in range(cy + 1, cy + pocket + 1): o(kx, y)  # карман
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
    lap = "{ " + ", ".join("{ %d, %d }" % c for c in cells) + " }, head = %d" % len(cells)
    return make(name, rows, objs, lap, length=Lr, vis="visP.lua")

def run(names):
    files = ['build/l6c/d_crane/%s.lua' % n for n in names]
    out = subprocess.run(['luajit', 'build/l6c/d_crane/q.lua'] + files, cwd='/home/user/Lapidus', capture_output=True, text=True)
    return out.stdout + out.stderr
