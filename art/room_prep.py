#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/room_prep.py — подготовка фона квартиры для Blender (art/blender/room.py):
   build/room/lvlNN.json   — геометрия: клетка, контуры комнаты (со скруглениями), сливы, стояки, кронштейны, трубы;
   build/room/lvlNN_paint.png — плоский слой задней стены: краска, трещины, шахты сливов с водой (экранные координаты);
   build/room/lvlNN_band.png  — маска полосы плитки вдоль комнаты (остальная кладка — бетон).
   python3 art/room_prep.py 1 2 ...  (без номеров — все квартиры)"""
import json, math, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2
from gen import G, Pa, R, C, Pg, n, dd, OPP, DV
from gen2 import Q, defs2, trace, simplify, loop_d, room_paint, sg

OUT = os.path.join(gen2.ROOT, 'build', 'room')
os.makedirs(OUT, exist_ok=True)
IDS = [int(a) for a in sys.argv[1:] if a.isdigit()]


def loop_pts(cs, rconv=.20, rconc=.42, k=8):
    """Те же скругления, что loop_d (art/gen2.py), но точками в клетках (x вправо, y вниз от угла поля)."""
    m, out = len(cs), []
    for i in range(m):
        p0, p1, p2 = cs[i - 1], cs[i], cs[(i + 1) % m]
        di = (sg(p1[0] - p0[0]), sg(p1[1] - p0[1]))
        do = (sg(p2[0] - p1[0]), sg(p2[1] - p1[1]))
        r = rconv if di[0] * do[1] - di[1] * do[0] < 0 else rconc
        A = (p1[0] - di[0] * r, p1[1] - di[1] * r)
        B = (p1[0] + do[0] * r, p1[1] + do[1] * r)
        for j in range(k + 1):
            t = j / k
            u = 1 - t
            out.append((u * u * A[0] + 2 * u * t * p1[0] + t * t * B[0], u * u * A[1] + 2 * u * t * p1[1] + t * t * B[1]))
    return out


def svg_png(path, body, extra=''):
    svg = path[:-4] + '.svg'
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080" viewBox="0 0 1920 1080">'
                '<defs>%s%s</defs>%s</svg>' % (gen.DEFS, extra, body))
    subprocess.run(['rsvg-convert', '-w', '1920', '-h', '1080', '-o', path, svg], check=True)


def drain_pit(cx, cy, c):
    """Шахта слива: тёмный колодец до края экрана, вода закручивается воронкой (решётку рисует Blender)."""
    s, x0, top = [], cx - c / 2, cy - c / 2
    s.append(R(x0, top, c, 1100 - top, 'url(#pitG)'))
    for k in range(4):
        r = c * (.14 + k * .09)
        s.append(Pa(dd('M', cx - r, cy + .22 * c, 'A', r, r * .35, 0, 0, 1, cx + r, cy + .22 * c), stroke=Q['water'], stroke_width=c * .035,
                    opacity='%.2f' % (.95 - k * .2), stroke_linecap='round'))
    for bx_, by_, br in ((-.12, .05, .03), (.1, -.05, .02), (.02, .12, .025)):
        s.append(C(cx + bx_ * c, cy + by_ * c, br * c, '#BDF3FF', opacity='.8'))
    return ''.join(s)


for lv in screens2.L:
    if IDS and lv['id'] not in IDS:
        continue
    grid = lv['grid']
    H, W = len(grid), len(grid[0])
    c, ox, oy = gen.geom(lv)
    ml, mt = math.ceil(ox / c) + 1, math.ceil(oy / c) + 1
    shaft = {x: min(y for y in range(1, H + 1) if grid[y - 1][x - 1] == '~') for x in range(1, W + 1)
             if any(grid[y - 1][x - 1] == '~' for y in range(1, H + 1))}

    def empty(x, y):
        if x in shaft and y > shaft[x]:
            return y <= H + mt
        if 1 <= x <= W and 1 <= y <= H:
            return grid[y - 1][x - 1] != '#'
        return False
    loops = [simplify(lp) for lp in trace(empty, (1 - ml, W + ml), (1 - mt, H + mt))]
    room_d = ' '.join(loop_d(lp, c, ox, oy, .20, .42) for lp in loops)
    terr_d = 'M -40 -40 H 1960 V 1120 H -40 Z ' + room_d
    extra = defs2(c, ox, oy, lv.get('tile', 'mint'))
    drains = [(x, y) for y in range(1, H + 1) for x in range(1, W + 1) if grid[y - 1][x - 1] == '~']
    pid = 'lvl%02d' % lv['id']
    paint = room_paint(ox, oy, W, H, c) + ''.join(drain_pit(ox + (x - .5) * c, oy + (y - .5) * c, c) for x, y in drains)
    svg_png(os.path.join(OUT, pid + '_paint.png'), paint, extra)
    band = R(0, 0, 1920, 1080, '#000000') + '<clipPath id="cT"><path d="%s" clip-rule="evenodd"/></clipPath>' % terr_d + \
        G(Pa(room_d, stroke='#FFFFFF', stroke_width=1.0 * c, stroke_linejoin='round'), clip_path='url(#cT)')
    svg_png(os.path.join(OUT, pid + '_band.png'), band, extra)

    wl = lambda x, y: 1 <= x <= W and 1 <= y <= H and grid[y - 1][x - 1] == '#'

    def ext(x, y, dy):  # докуда идёт стояк сквозь стену: до края экрана или до свободной клетки (в клетках поля)
        yy = y + dy
        while 1 <= yy <= H and grid[yy - 1][x - 1] == '#':
            yy += dy
        if yy < 1 or yy > H:
            return (-20 - oy) / c if dy < 0 else (1100 - oy) / c
        return yy if dy < 0 else yy - 1
    objs = []
    for ob in lv['objects']:
        k = ob['kind']
        if k not in ('source', 'stub', 'pipe'):
            continue
        x, y = ob['at']
        o = {'kind': k, 'x': x - .5, 'y': y - .5, 'ports': ob.get('ports', {})}
        if k == 'source':
            o['top'], o['bot'] = ext(x, y, -1), ext(x, y, 1)
            o['capT'] = o['top'] >= 0          # конец в свободной клетке, а не за краем экрана — нужна заглушка
            o['capB'] = o['bot'] <= H
        if k == 'stub':
            pd = list(o['ports'])[0]
            cand = [OPP[pd]] + [m for m in ('left', 'right', 'up', 'down') if m not in (pd, OPP[pd])]
            o['mount'] = next((m for m in cand if wl(x + DV[m][0], y + DV[m][1])), OPP[pd])
        objs.append(o)
    data = {'id': lv['id'], 'c': c, 'ox': ox, 'oy': oy, 'W': W, 'H': H, 'tile': gen.TILE[lv.get('tile', 'mint')],
            'loops': [loop_pts(lp) for lp in loops], 'drains': [(x - .5, y - .5) for x, y in drains], 'objects': objs}
    with open(os.path.join(OUT, pid + '.json'), 'w') as f:
        json.dump(data, f)
    print(pid, 'c=%d' % c, 'loops', len(loops), 'objects', len(objs))
