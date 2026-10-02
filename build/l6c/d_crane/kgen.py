#!/usr/bin/env python3
# kgen.py — локальная доводка ядра K3 («колонна с развилкой J, боковой ход S с муфтой, кольцо через нижний коридор»).
# Параметры: высота колонки над J (up), длина S до муфты (sfree), клетка ловушки муфты, нижний коридор влево (left),
# положение стойки (conn), старт Лапидуса. Печатает метрики (без решений).
import sys, itertools, subprocess
sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from mk import make

def level(name, up, sfree, left, extra_right, start, Lrange=(3,5), nip_below=False):
    # колонна x=cx; J на ряду jy; колонка на ряду jy-up-1 (над ниппелем)
    cx = 2 + left + 1
    jy = up + 2 + (1 if not nip_below else 0)
    heater_y = jy - up - 1 if not nip_below else jy - up - 1
    H = jy + 4
    W = cx + sfree + 4 + extra_right
    g = [['#'] * W for _ in range(H)]
    def o(x, y): g[y-1][x-1] = '.'
    # колонна от колонки до нижнего коридора
    for y in range(heater_y + 1, jy + 3): o(cx, y)
    # S: J + sfree клеток + клетка ловушки + клетка муфты + стойка
    catch_x = cx + sfree + 1
    for x in range(cx, catch_x + 3): o(x, jy)
    conn_x = catch_x + 2
    o(conn_x, jy + 1)
    # нижний коридор
    for x in range(cx - left, conn_x + 1 + extra_right): o(x, jy + 2)
    rows = [''.join(r) for r in g]
    objs = ['{ kind = "fixture", what = "heater", at = { %d, %d }, ports = { down = "V" } }' % (cx, heater_y),
            '{ kind = "source", at = { %d, %d }, ports = { up = "N" } }' % (catch_x, jy + 1),
            '{ kind = "fitting", what = "elbow", tag = "C", at = { %d, %d }, ports = { left = "V", down = "V" } }' % (catch_x + 1, jy)]
    # ниппель: над J (на J) или под J
    ny = jy - 1 if not nip_below else jy + 1
    objs.append('{ kind = "fitting", what = "nipple", tag = "B", at = { %d, %d }, ports = { up = "N", down = "N" } }' % (cx, ny))
    # источник стоит в стене под ловушкой: сделать клетку пустой в сетке
    r = list(rows[jy]); r[catch_x - 1] = '.'; rows[jy] = ''.join(r)
    r = list(rows[heater_y - 1]); r[cx - 1] = '.'; rows[heater_y - 1] = ''.join(r)
    cells = start(cx, jy)
    lap = "{ " + ", ".join("{ %d, %d }" % c for c in cells) + " }, head = %d" % len(cells)
    return make(name, rows, objs, lap, length=Lrange, vis="visK.lua", extra="  shelf = %d,\n" % jy)

if __name__ == '__main__':
    pass

def startA(L):
    # голова в J под ниппелем, тело вниз по колонне и вправо по нижнему коридору
    def f(cx, jy):
        path = [(cx, jy), (cx, jy+1), (cx, jy+2)] + [(cx + i, jy + 2) for i in range(1, 6)]
        body = path[:L]
        return list(reversed(body))  # от ног к голове
    return f
def startB(L):
    def f(cx, jy):
        path = [(cx, jy), (cx, jy+1), (cx, jy+2)] + [(cx + i, jy + 2) for i in range(1, 6)]
        return path[:L]  # ноги в J
    return f

def run(names):
    files = ['build/l6c/d_crane/%s.lua' % n for n in names]
    out = subprocess.run(['luajit', 'build/l6c/d_crane/q.lua'] + files, cwd='/home/user/Lapidus', capture_output=True, text=True)
    print(out.stdout + out.stderr)

if __name__ == '__main__':
    names = []
    i = 0
    for up in (2, 3):
        for sfree in (1, 2):
            for left in (0, 2):
                for st, sn in ((startA, 'A'), (startB, 'B')):
                    n = 'kg_u%d_s%d_l%d_%s' % (up, sfree, left, sn)
                    level(n, up, sfree, left, 0, st(5))
                    names.append(n)
    run(names)
