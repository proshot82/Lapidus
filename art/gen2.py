#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/gen2.py — второй проход арта после отзыва Lao «арт ужасен»: стиль-кадр квартиры 1.

Против art/gen.py:
- кладка — сплошные скруглённые массы по контуру поля (а не сетка одинаковых плиток), плитка только
  облицовкой по кромке, бетон с зерном внутри, тень от кладки и затенение углов на стене;
- контур «от руки» (лёгкое дрожание), объёмная светотень от одного источника — сверху слева;
- герой крупнее: гайка с гранями, глаза навыкате, пенная шевелюра, ноги с пальцами; мягкая тень;
- фон — комната: масляная панель, побелка с пятнами и трещинами, лампа, виньетка;
- интерфейс предметный: эмалевая табличка квартиры, бумажная бирка, механический счётчик,
  латунные кнопки-вентили."""
import json, math, os, random, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen import n, R, C, E, Ln, Pg, Pa, G, T, dd, smooth, ribs, dname, TILE, DV, OPP, HAND

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'build', 'review2')
os.makedirs(OUT, exist_ok=True)
Q = dict(ol='#2B2118', hose='#F6F3EA', hose_mid='#DED7C5', hose_sh='#B2A88E', rib='#9C927A', wash='#D8D2C3',
         stripe='#6A4434', skin='#F2BC9C', water='#2EC4F1', foam_sh='#BCD4E3', red='#C83E2C', cream='#F4EEDC', plate='#2A2622')


def orient(body, dr, cx, cy):
    if dr == 'right':
        return body
    if dr == 'left':
        return '<g transform="translate(%s 0) scale(-1 1)">%s</g>' % (n(2 * cx), body)
    return '<g transform="rotate(%d %s %s)">%s</g>' % (-90 if dr == 'up' else 90, n(cx), n(cy), body)


def defs2(c, ox, oy, tile):
    base, grout, hi = TILE[tile]
    h = c / 2
    g = lambda i, stops, x2='0', y2='1': ('<linearGradient id="%s" x1="0" y1="0" x2="%s" y2="%s">' % (i, x2, y2)
                                          + ''.join('<stop offset="%s" stop-color="%s"/>' % st for st in stops) + '</linearGradient>')
    return (g('nutG', [('0', '#F8E29A'), ('.3', '#F8E29A'), ('.3', '#D1A238'), ('.7', '#D1A238'), ('.7', '#8E6819'), ('1', '#8E6819')])
            + g('nutGd', [('0', '#E2C57C'), ('.3', '#E2C57C'), ('.3', '#AA8127'), ('.7', '#AA8127'), ('.7', '#6B4E11'), ('1', '#6B4E11')])
            + g('cylG', [('0', '#FBE7A6'), ('.28', '#E2B54B'), ('.62', '#B08424'), ('1', '#6E500F')])
            + g('cylGd', [('0', '#E8CF88'), ('.28', '#C39837'), ('.62', '#8E6A1C'), ('1', '#58400C')])
            + g('ironV', [('0', '#3A4047'), ('.22', '#A3ADB8'), ('.45', '#68717C'), ('.8', '#454C54'), ('1', '#2C3136')], '1', '0')
            + g('ironH', [('0', '#3A4047'), ('.22', '#A3ADB8'), ('.45', '#68717C'), ('.8', '#454C54'), ('1', '#2C3136')])
            + g('enam', [('0', '#FFFFFF'), ('.56', '#F7F8F6'), ('.56', '#D3DBE4'), ('1', '#B7C2CF')], '1', '1')
            + g('skinG', [('0', '#F6CBAA'), ('.58', '#F0BD99'), ('.58', '#D89C7B'), ('1', '#C98A6B')], '1', '1')
            + g('steelG', [('0', '#F1F4F7'), ('1', '#98A2AC')])
            + g('panelG', [('0', '#6A8C7C'), ('1', '#48665A')]) + g('concG', [('0', '#A99F90'), ('1', '#7A7266')])
            + g('pitG', [('0', '#173340'), ('1', '#04080A')]) + g('waterG', [('0', '#9BE8FC'), ('1', '#1682B5')])
            + '<radialGradient id="lamp" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#FFF1C9" stop-opacity=".55"/><stop offset="1" stop-color="#FFF1C9" stop-opacity="0"/></radialGradient>'
            + '<radialGradient id="vg2" cx=".5" cy=".42" r=".8"><stop offset=".5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".5"/></radialGradient>'
            + '<radialGradient id="glow" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#7FE2FF" stop-opacity=".6"/><stop offset="1" stop-color="#7FE2FF" stop-opacity="0"/></radialGradient>'
            + '<pattern id="tiles" patternUnits="userSpaceOnUse" x="%s" y="%s" width="%s" height="%s">' % (n(ox), n(oy), n(h), n(h))
            + R(0, 0, h, h, grout) + R(c * .022, c * .022, h - c * .044, h - c * .044, base, rx=c * .05)
            + Ln(c * .07, c * .07, h - c * .13, c * .07, hi, c * .03, opacity='.9')
            + Ln(h - c * .07, c * .10, h - c * .07, h - c * .08, '#000000', c * .02, opacity='.12') + '</pattern>'
            + '<filter id="wob" x="-3%" y="-3%" width="106%" height="106%"><feTurbulence type="fractalNoise" baseFrequency=".03" numOctaves="2" seed="7" result="t"/>'
              '<feDisplacementMap in="SourceGraphic" in2="t" scale="4" xChannelSelector="R" yChannelSelector="G"/></filter>'
            + '<filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".7" numOctaves="2" seed="11" result="n"/>'
              '<feColorMatrix in="n" type="matrix" values="0 0 0 0 .18  0 0 0 0 .15  0 0 0 0 .12  0 0 0 .9 -.28" result="k"/><feComposite in="k" in2="SourceGraphic" operator="in"/></filter>'
            + '<filter id="blotch" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".005 .011" numOctaves="3" seed="5" result="n"/>'
              '<feColorMatrix in="n" type="matrix" values="0 0 0 0 .42  0 0 0 0 .33  0 0 0 0 .2  0 0 0 1.6 -.78" result="k"/><feComposite in="k" in2="SourceGraphic" operator="in"/></filter>'
            + '<filter id="bl8" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="8"/></filter>'
            + '<filter id="bl18" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="18"/></filter>'
            + '<filter id="dsh" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="5" result="b"/><feOffset in="b" dx="5" dy="8" result="o"/>'
              '<feComponentTransfer in="o" result="s"><feFuncA type="linear" slope=".45"/></feComponentTransfer><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter>')


# ---------- контур кладки

def trace(empty, xr, yr):
    edges = {}

    def add(a, b):
        edges.setdefault(a, []).append(b)
    for y in range(yr[0], yr[1] + 1):
        for x in range(xr[0], xr[1] + 1):
            if not empty(x, y):
                continue
            if not empty(x, y - 1):
                add((x, y - 1), (x - 1, y - 1))
            if not empty(x, y + 1):
                add((x - 1, y), (x, y))
            if not empty(x - 1, y):
                add((x - 1, y - 1), (x - 1, y))
            if not empty(x + 1, y):
                add((x, y), (x, y - 1))
    loops = []
    while True:
        start = next((k for k, v in edges.items() if v), None)
        if start is None:
            return loops
        loop, cur, pd = [start], start, None
        while True:
            outs = edges[cur]
            if pd is None or len(outs) == 1:
                nxt = outs[0]
            else:
                left = (pd[1], -pd[0])
                nxt = min(outs, key=lambda b: 0 if (b[0] - cur[0], b[1] - cur[1]) == left else (1 if (b[0] - cur[0], b[1] - cur[1]) == pd else 2))
            outs.remove(nxt)
            pd = (nxt[0] - cur[0], nxt[1] - cur[1])
            cur = nxt
            if cur == start:
                break
            loop.append(cur)
        loops.append(loop)


def sg(v):
    return (v > 0) - (v < 0)


def simplify(loop):
    out, m = [], len(loop)
    for i in range(m):
        p0, p1, p2 = loop[i - 1], loop[i], loop[(i + 1) % m]
        if (sg(p1[0] - p0[0]), sg(p1[1] - p0[1])) != (sg(p2[0] - p1[0]), sg(p2[1] - p1[1])):
            out.append(p1)
    return out


def loop_d(cs, c, ox, oy, rconv, rconc):
    m, pts = len(cs), []
    for i in range(m):
        p0, p1, p2 = cs[i - 1], cs[i], cs[(i + 1) % m]
        di = (sg(p1[0] - p0[0]), sg(p1[1] - p0[1]))
        do = (sg(p2[0] - p1[0]), sg(p2[1] - p1[1]))
        r = (rconv if di[0] * do[1] - di[1] * do[0] < 0 else rconc) * c
        V = (ox + p1[0] * c, oy + p1[1] * c)
        pts.append(((V[0] - di[0] * r, V[1] - di[1] * r), V, (V[0] + do[0] * r, V[1] + do[1] * r)))
    d = 'M %s %s' % (n(pts[-1][2][0]), n(pts[-1][2][1]))
    for A, V, B in pts:
        d += ' L %s %s Q %s %s %s %s' % (n(A[0]), n(A[1]), n(V[0]), n(V[1]), n(B[0]), n(B[1]))
    return d + ' Z'


# ---------- фон

def room_paint(ox, oy, W, H, c):
    split = oy + H * c * .34
    rnd = random.Random(4)
    s = [R(0, 0, 1920, split, Q['wash']), R(0, 0, 1920, split, '#000000', filter='url(#blotch)'), R(0, split, 1920, 1080 - split, 'url(#panelG)')]
    for i in range(22):
        x, y, r = rnd.uniform(0, 1920), split + rnd.uniform(.08, .7) * c, rnd.uniform(.05, .16) * c
        s.append(Pg([(x + math.cos(k * math.pi / 4) * r * rnd.uniform(.6, 1.2), y + math.sin(k * math.pi / 4) * r * rnd.uniform(.5, 1.0)) for k in range(8)], '#C3C9BC', opacity='.5'))
    s.append(R(0, split - .035 * c, 1920, .07 * c, Q['stripe']))
    s.append(R(0, split + .09 * c, 1920, .12 * c, '#FFFFFF', opacity='.07'))
    py = split + 1.3 * c
    s.append(R(0, py, 1920, .16 * c, '#8A9C93', opacity='.35'))
    for bx in range(80, 1920, 420):
        s.append(R(bx, py - .06 * c, .08 * c, .28 * c, '#6C7C74', opacity='.35'))
    for k in range(6):
        x, y = rnd.uniform(100, 1800), rnd.uniform(30, split - 60)
        d = 'M %s %s' % (n(x), n(y))
        for j in range(5):
            x += rnd.uniform(-30, 30)
            y += rnd.uniform(8, 24)
            d += ' L %s %s' % (n(x), n(y))
        s.append(Pa(d, stroke='#877F71', stroke_width=2, opacity='.55'))
    s.append(E(380, 110, 980, 580, 'url(#lamp)'))
    s.append(R(0, 0, 1920, 1080, 'url(#vg2)'))
    return ''.join(s)


# ---------- детали

def port2(cx, cy, c, dr, th, fixed=False):
    o, lw = Q['ol'], c * .04
    nut, cyl = ('url(#nutGd)', 'url(#cylGd)') if fixed else ('url(#nutG)', 'url(#cylG)')
    s = []
    if th == 'N':
        s.append(R(cx + .16 * c, cy - .25 * c, .13 * c, .50 * c, nut, rx=.035 * c, stroke=o, stroke_width=lw))
        s.append(R(cx + .27 * c, cy - .17 * c, .31 * c, .34 * c, cyl, rx=.06 * c, stroke=o, stroke_width=lw))
        for i in range(4):
            x = cx + .31 * c + i * .062 * c
            s.append(Ln(x, cy - .155 * c, x + .045 * c, cy + .155 * c, '#5E4410', c * .026))
            s.append(Ln(x + .022 * c, cy - .15 * c, x + .062 * c, cy + .12 * c, '#FBE7A6', c * .012, opacity='.8'))
    else:
        s.append(R(cx + .16 * c, cy - .30 * c, .37 * c, .60 * c, nut, rx=.05 * c, stroke=o, stroke_width=lw))
        s.append(Ln(cx + .28 * c, cy - .28 * c, cx + .28 * c, cy + .28 * c, '#000000', c * .018, opacity='.25'))
        s.append(E(cx + .52 * c, cy, .07 * c, .19 * c, '#1A120C', stroke=o, stroke_width=c * .03))
        for k in (-.11, -.035, .035, .11):
            s.append(Ln(cx + .47 * c, cy + k * c, cx + .55 * c, cy + k * c + .012 * c, '#9C7A2E', c * .02))
    return orient(''.join(s), dr, cx, cy)


def source2(cx, cy, c, ports, top=-20, bot=1100, pressure=0):
    o, s = Q['ol'], []
    s.append(R(cx - .24 * c, top, .48 * c, bot - top, 'url(#ironV)', stroke=o, stroke_width=c * .045))
    rnd = random.Random(int(cx))
    for k in range(10):
        s.append(E(cx + rnd.uniform(-.12, .12) * c, rnd.uniform(top + .1 * c, bot - .1 * c), rnd.uniform(.05, .12) * c, rnd.uniform(.08, .25) * c,
                   '#8E4F2B', opacity='%.2f' % rnd.uniform(.25, .5)))
    for yy in (cy - .56 * c, cy + .44 * c):
        s.append(R(cx - .32 * c, yy, .64 * c, .13 * c, 'url(#ironH)', rx=.035 * c, stroke=o, stroke_width=c * .035))
        for bx in (-.24, .24):
            s.append(C(cx + bx * c, yy + .065 * c, .03 * c, '#C9CFD6', stroke=o, stroke_width=c * .015))
    for dr, th in ports.items():
        s.append(orient(R(cx + .10 * c, cy - .17 * c, .14 * c, .34 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .04), dr, cx, cy))
        s.append(port2(cx, cy, c, dr, th, fixed=True))
    s.append(R(cx - .30 * c, cy - .36 * c, .60 * c, .08 * c, '#4A5058', rx=.03 * c, stroke=o, stroke_width=c * .03))
    wx, wy, wr = cx, cy + .12 * c, .20 * c
    s.append(C(wx, wy, wr, 'none', stroke=o, stroke_width=c * .10))
    s.append(C(wx, wy, wr, 'none', stroke=Q['red'], stroke_width=c * .062))
    s.append(Pa(dd('M', wx - wr * .85, wy - wr * .45, 'A', wr, wr, 0, 0, 1, wx - wr * .1, wy - wr * .98), stroke='#F59A83', stroke_width=c * .02, stroke_linecap='round'))
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        s.append(Ln(wx, wy, wx + math.cos(a) * wr, wy + math.sin(a) * wr, o, c * .07))
        s.append(Ln(wx, wy, wx + math.cos(a) * wr, wy + math.sin(a) * wr, Q['red'], c * .04))
    s.append(C(wx, wy, .06 * c, 'url(#cylG)', stroke=o, stroke_width=c * .03))
    if pressure > 0:
        s.append(gauge2(cx, cy, c, pressure, -1 if ports.get('right') else 1))
    return ''.join(s)


def gauge2(cx, cy, c, pressure, side=1, vmax=3):
    """Манометр на стояке (§4): латунный корпус, шкала 0–vmax, красная зона у максимума, стрелка на напоре уровня."""
    o, s = Q['ol'], []
    gx, gy, r = cx + side * .66 * c, cy - .24 * c, .25 * c
    s.append(R(min(cx + side * .20 * c, gx - side * .20 * c), gy - .05 * c, abs(gx - side * .20 * c - cx - side * .20 * c), .10 * c,
               'url(#ironH)', stroke=o, stroke_width=c * .03))
    s.append(C(gx, gy, r, 'url(#cylGd)', stroke=o, stroke_width=c * .045))
    s.append(C(gx, gy, r * .78, '#FBF8F0', stroke=o, stroke_width=c * .02))

    def pt(v, rr):
        a = math.radians(225 - 270 * v / vmax)
        return gx + rr * math.cos(a), gy - rr * math.sin(a)
    x1, y1 = pt(vmax * .72, r * .66)
    x2, y2 = pt(vmax, r * .66)
    s.append(Pa(dd('M', x1, y1, 'A', r * .66, r * .66, 0, 0, 1, x2, y2), fill='none', stroke=Q['red'], stroke_width=c * .045))
    for k in range(vmax + 1):
        ax, ay = pt(k, r * .74)
        bx, by = pt(k, r * .56)
        s.append(Ln(ax, ay, bx, by, o, c * .025))
    nx, ny = pt(min(pressure, vmax), r * .62)
    s.append(Ln(gx, gy, nx, ny, o, c * .05) + Ln(gx, gy, nx, ny, Q['red'], c * .028))
    s.append(C(gx, gy, .045 * c, 'url(#cylG)', stroke=o, stroke_width=c * .02))
    return ''.join(s)


def stub2(cx, cy, c, pd, th, mount):
    o, s = Q['ol'], []
    arm = (R(cx - .02 * c, cy - .18 * c, .54 * c, .36 * c, 'url(#ironH)', stroke=o, stroke_width=c * .04)
           + R(cx + .40 * c, cy - .30 * c, .12 * c, .60 * c, 'url(#ironH)', rx=.03 * c, stroke=o, stroke_width=c * .035)
           + C(cx + .46 * c, cy - .21 * c, .025 * c, '#C9CFD6') + C(cx + .46 * c, cy + .21 * c, .025 * c, '#C9CFD6'))
    s.append(orient(arm, mount, cx, cy))
    if mount != OPP[pd]:
        s.append(C(cx, cy, .23 * c, 'url(#ironH)', stroke=o, stroke_width=c * .04))
    s.append(orient(R(cx - .02 * c, cy - .18 * c, .22 * c, .36 * c, 'url(#ironH)', stroke=o, stroke_width=c * .04), pd, cx, cy))
    s.append(port2(cx, cy, c, pd, th, fixed=True))
    return ''.join(s)


def face2(x, y, c, mood, look=(0, 0)):
    o, s = Q['ol'], []
    for sx in (-1, 1):
        ex = x + sx * .14 * c
        if mood == 'happy':
            s.append(Pa(dd('M', ex - .07 * c, y + .01 * c, 'Q', ex, y - .09 * c, ex + .07 * c, y + .01 * c), stroke=o, stroke_width=c * .035, stroke_linecap='round'))
        else:
            s.append(E(ex, y, .075 * c, .085 * c, '#FFFFFF', stroke=o, stroke_width=c * .03))
            s.append(C(ex + look[0] * .022 * c, y + .02 * c, .035 * c, o))
            s.append(C(ex + look[0] * .022 * c - .012 * c, y + .006 * c, .011 * c, '#FFFFFF'))
            s.append(Pa(dd('M', ex - .08 * c, y - .012 * c, 'Q', ex, y - .10 * c, ex + .08 * c, y - .012 * c, 'Z'), '#E3E8EE', stroke=o, stroke_width=c * .028))
            s.append(Ln(ex + sx * .09 * c, y - .15 * c, ex - sx * .06 * c, y - .10 * c, o, c * .04))
    if mood == 'happy':
        s.append(Pa(dd('M', x - .12 * c, y + .08 * c, 'Q', x, y + .26 * c, x + .12 * c, y + .08 * c, 'Z'), '#7A2D2A', stroke=o, stroke_width=c * .03, stroke_linejoin='round'))
    else:
        s.append(Pa(dd('M', x - .10 * c, y + .18 * c, 'Q', x - .05 * c, y + .12 * c, x, y + .16 * c, 'Q', x + .05 * c, y + .20 * c, x + .10 * c, y + .14 * c),
                    stroke=o, stroke_width=c * .035, stroke_linecap='round'))
    return ''.join(s)


def bath2(cx, cy, c, wet=False):
    o, s, bx = Q['ol'], [], cx + .20 * c
    for fx in (-1, 1):
        x = bx + fx * .36 * c
        s.append(Pa(dd('M', x - .07 * c, cy + .34 * c, 'L', x + .07 * c, cy + .34 * c, 'L', x + .11 * c, cy + .50 * c, 'Q', x, cy + .56 * c, x - .11 * c, cy + .50 * c, 'Z'),
                    'url(#cylG)', stroke=o, stroke_width=c * .035, stroke_linejoin='round'))
        for tx in (-.05, 0, .05):
            s.append(Ln(x + tx * c, cy + .47 * c, x + tx * c, cy + .53 * c, '#6E500F', c * .015))
    body = dd('M', bx - .56 * c, cy - .16 * c, 'C', bx - .56 * c, cy + .28 * c, bx - .42 * c, cy + .40 * c, bx - .20 * c, cy + .40 * c,
              'L', bx + .20 * c, cy + .40 * c, 'C', bx + .42 * c, cy + .40 * c, bx + .56 * c, cy + .28 * c, bx + .56 * c, cy - .16 * c, 'Z')
    s.append(Pa(body, 'url(#enam)', stroke=o, stroke_width=c * .045, stroke_linejoin='round'))
    s.append(Pa(dd('M', bx - .44 * c, cy - .06 * c, 'Q', bx - .44 * c, cy + .22 * c, bx - .26 * c, cy + .30 * c), stroke='#FFFFFF', stroke_width=c * .035, stroke_linecap='round', opacity='.9'))
    if wet:
        s.append(E(bx, cy - .20 * c, .52 * c, .08 * c, 'url(#waterG)', stroke=o, stroke_width=c * .03))
    s.append(R(bx - .62 * c, cy - .23 * c, 1.24 * c, .13 * c, 'url(#enam)', rx=.065 * c, stroke=o, stroke_width=c * .045))
    s.append(Ln(bx - .52 * c, cy - .205 * c, bx + .30 * c, cy - .205 * c, '#FFFFFF', c * .025, opacity='.95'))
    s.append(face2(bx, cy + .10 * c, c, 'happy' if wet else 'grumpy', look=(-1, 0)))
    s.append(R(cx - .24 * c, cy - .10 * c, .22 * c, .16 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .035))
    return ''.join(s)


def drain2(cx, cy, c, bottom=1100):
    o, s, x0, top = Q['ol'], [], cx - c / 2, cy - c / 2
    s.append(R(x0, top, c, bottom - top, 'url(#pitG)'))
    for k in range(4):
        r = c * (.14 + k * .09)
        s.append(Pa(dd('M', cx - r, cy + .22 * c, 'A', r, r * .35, 0, 0, 1, cx + r, cy + .22 * c), stroke=Q['water'], stroke_width=c * .035,
                    opacity='%.2f' % (.95 - k * .2), stroke_linecap='round'))
    s.append(E(cx, top + .08 * c, .46 * c, .07 * c, 'none', stroke='#3C434A', stroke_width=c * .06))
    for k in (-.3, -.15, 0, .15, .3):
        s.append(Ln(cx + k * c, top + .03 * c, cx + k * c, top + .13 * c, '#3C434A', c * .03))
    for bx_, by_, br in ((-.12, .05, .03), (.1, -.05, .02), (.02, .12, .025)):
        s.append(C(cx + bx_ * c, cy + by_ * c, br * c, '#BDF3FF', opacity='.8'))
    return ''.join(s)


# ---------- герой

def fluff2(x, y, c):
    return ''.join(Pa(dd('M', x + fx * c, y + fy * c, 'q', .06 * c, -.07 * c * sx, .12 * c, 0, 't', .09 * c, .04 * c * sx), stroke='#FFFFFF', stroke_width=c * .035, stroke_linecap='round')
                   for fx, fy, sx in ((-.02, -.26, 1), (.02, .22, -1), (.06, -.10, 1), (.04, .08, -1)))


def heel2(pt, dr, c, active, screwed):
    cx, cy = pt
    o, s = Q['ol'], []
    for i in range(4):
        tx = cx - .19 * c + i * .07 * c
        if active:
            s.append(E(tx, cy + .36 * c, .042 * c, .075 * c, Q['skin'], stroke=o, stroke_width=c * .03, transform='rotate(%d %s %s)' % ((i - 1.5) * 10, n(tx), n(cy + .36 * c))))
            s.append(E(tx, cy + .405 * c, .022 * c, .016 * c, '#FFE9DE'))
        else:
            s.append(E(tx + .01 * c, cy + .31 * c, .04 * c, .04 * c, Q['skin'], stroke=o, stroke_width=c * .03))
    s.append(R(cx - .24 * c, cy - .31 * c, .26 * c, .62 * c, 'url(#nutG)', rx=.07 * c, stroke=o, stroke_width=c * .045))
    s.append(R(cx + .01 * c, cy - .20 * c, .45 * c, .40 * c, 'url(#cylG)', rx=.08 * c, stroke=o, stroke_width=c * .04))
    for i in range(5):
        x = cx + .08 * c + i * .07 * c
        s.append(Ln(x, cy - .185 * c, x + .05 * c, cy + .185 * c, '#5E4410', c * .028))
        s.append(Ln(x + .025 * c, cy - .17 * c, x + .065 * c, cy + .12 * c, '#FBE7A6', c * .013, opacity='.8'))
    if screwed:
        s.append(fluff2(cx + .47 * c, cy, c))
    return orient(''.join(s), dr, cx, cy)


def head2(pt, dr, c, active, screwed):
    cx, cy = pt
    o, s = Q['ol'], []
    dx, dy = DV[dr]
    if dr == 'up':
        foam = [(-.42, .05, .13), (-.46, -.12, .11), (.42, .05, .13), (.46, -.12, .11)]
    elif dr == 'down':
        foam = [(-.26, -.42, .15), (-.06, -.52, .17), (.16, -.46, .15), (.32, -.30, .11), (-.38, -.26, .11)]
    else:
        foam = [(-dx * .30, -.44, .15), (-dx * .10, -.54, .17), (dx * .10, -.50, .14), (-dx * .42, -.28, .12), (dx * .24, -.40, .10)]
    for fx, fy, fr in foam:
        s.append(C(cx + fx * c, cy + fy * c, fr * c + .022 * c, o))
    for fx, fy, fr in foam:
        s.append(C(cx + fx * c, cy + fy * c, fr * c, '#FFFFFF'))
        s.append(C(cx + fx * c + fr * c * .3, cy + fy * c + fr * c * .35, fr * c * .45, Q['foam_sh'], opacity='.65'))
    nut = [R(cx - .30 * c, cy - .34 * c, .60 * c, .68 * c, 'url(#nutG)', rx=.10 * c, stroke=o, stroke_width=c * .045),
           R(cx + .22 * c, cy - .31 * c, .07 * c, .62 * c, '#000000', rx=.03 * c, opacity='.14'),
           R(cx - .34 * c, cy - .20 * c, .08 * c, .40 * c, 'url(#cylG)', rx=.03 * c, stroke=o, stroke_width=c * .03),
           E(cx + .31 * c, cy + .02 * c, .10 * c, .20 * c, '#1A120C', stroke=o, stroke_width=c * .035)]
    for k in (-.12, -.04, .04, .12):
        nut.append(Ln(cx + .25 * c, cy + k * c, cx + .35 * c, cy + k * c + .015 * c, '#B8913A', c * .026))
    if screwed:
        nut.append(fluff2(cx + .44 * c, cy, c))
    s.append(orient(''.join(nut), dr, cx, cy))
    eyes = {'right': [(-.08, -.30), (.14, -.30)], 'left': [(.08, -.30), (-.14, -.30)],
            'down': [(-.13, -.20), (.13, -.20)], 'up': [(-.13, .12), (.13, .12)]}[dr]
    for ex, ey in eyes:
        ex, ey = cx + ex * c, cy + ey * c
        if active:
            s.append(E(ex, ey, .105 * c, .125 * c, '#FFFFFF', stroke=o, stroke_width=c * .035))
            s.append(C(ex + dx * .035 * c, ey + dy * .035 * c + .01 * c, .05 * c, o))
            s.append(C(ex + dx * .035 * c - .018 * c, ey + dy * .035 * c - .01 * c, .016 * c, '#FFFFFF'))
        else:
            s.append(E(ex, ey, .105 * c, .125 * c, '#E8C66E', stroke=o, stroke_width=c * .035))
            s.append(Pa(dd('M', ex - .08 * c, ey + .01 * c, 'Q', ex, ey + .07 * c, ex + .08 * c, ey + .01 * c), stroke=o, stroke_width=c * .032, stroke_linecap='round'))
    return ''.join(s)


def hero(pts, c, Lmin, Lmax, active='head', screwed=(False, False), ring=True, wet=False):
    o, w = Q['ol'], .56 * c
    dstr, dense = smooth(pts, c)
    base = dict(stroke_linecap='round', stroke_linejoin='round')
    ax, ay = pts[-1] if active == 'head' else pts[0]
    s = [C(ax, ay, .8 * c, 'url(#glow)'),
         C(ax, ay, .64 * c, 'none', stroke=Q['water'], stroke_width=c * .035, opacity='.85', stroke_dasharray='%s %s' % (n(c * .16), n(c * .10)))] if ring else []
    b = [Pa(dstr, stroke=o, stroke_width=w + .09 * c, **base), Pa(dstr, stroke=Q['hose_sh'], stroke_width=w, **base),
         G(Pa(dstr, stroke=Q['hose_mid'], stroke_width=w * .80, **base), transform='translate(%s %s)' % (n(-.035 * c), n(-.05 * c))),
         G(Pa(dstr, stroke=Q['hose'], stroke_width=w * .46, **base), transform='translate(%s %s)' % (n(-.06 * c), n(-.10 * c)))]
    per = 4 + 4.0 * (Lmax - len(pts)) / max(1, Lmax - Lmin)
    for px, py, tx, ty in ribs(dense, c / per, [(pts[-1], .45 * c), (pts[0], .40 * c)]):
        hw = w * .46
        a, bb, m = (px + ty * hw, py - tx * hw), (px - ty * hw, py + tx * hw), (px + tx * .07 * c, py + ty * .07 * c)
        b.append(Pa(dd('M', a[0], a[1], 'Q', m[0], m[1], bb[0], bb[1]), stroke=Q['rib'], stroke_width=c * .03, stroke_linecap='round'))
        k = .035 * c
        b.append(Pa(dd('M', a[0] - tx * k, a[1] - ty * k, 'Q', m[0] - tx * k, m[1] - ty * k, bb[0] - tx * k, bb[1] - ty * k), stroke='#FFFFFF', stroke_width=c * .016, opacity='.7', stroke_linecap='round'))
    if wet:
        b.append(Pa(dstr, stroke=Q['water'], stroke_width=c * .12, stroke_dasharray='%s %s' % (n(c * .22), n(c * .10)), **base))
        b.append(Pa(dstr, stroke='#BDF3FF', stroke_width=c * .035, stroke_dasharray='%s %s' % (n(c * .12), n(c * .2)), **base))
    b.append(heelL(pts[0], dname(pts[0], pts[1]), c, active == 'heel', screwed[0]))
    b.append(headL(pts[-1], dname(pts[-1], pts[-2]), c, active == 'head', screwed[1]))
    s.append(G(''.join(b), filter='url(#dsh)'))
    return ''.join(s)


# ---------- интерфейс

def button2(kind, x, y):
    o, wc = Q['ol'], Q['cream']
    s = [C(x + 3, y + 6, 62, '#000000', opacity='.35'), C(x, y, 60, 'url(#cylG)', stroke=o, stroke_width=5), C(x, y, 46, '#2A2622', stroke=o, stroke_width=3)]
    if kind == 'undo':
        s.append(Pa(dd('M', x + 14, y + 16, 'A', 20, 20, 0, 1, 0, x - 19, y + 1), stroke=wc, stroke_width=7, stroke_linecap='round'))
        s.append(Pg([(x - 30, y - 3), (x - 8, y - 3), (x - 19, y + 15)], wc))
    elif kind == 'restart':
        s.append(Pa(dd('M', x + 19, y + 2, 'A', 19, 19, 0, 1, 1, x + 7, y - 18), stroke=wc, stroke_width=7, stroke_linecap='round'))
        s.append(Pg([(x + 1, y - 29), (x + 18, y - 18), (x + 1, y - 7)], wc))
    elif kind == 'hint':
        s.append(T(x, y + 20, '?', 60, wc, weight='bold', anchor='middle'))
    else:
        for k in (-14, 0, 14):
            s.append(Ln(x - 20, y + k, x + 20, y + k, wc, 7))
    return ''.join(s)


def hud2(lv, ox, moves=0, active='head'):
    o, px, s = Q['ol'], ox / 2, []
    s.append(G(E(px, 112, 112, 76, '#EFEADF', stroke=o, stroke_width=5) + E(px, 112, 98, 62, '#1F4E97') + E(px, 112, 90, 54, 'none', stroke='#FFFFFF', stroke_width=4)
               + T(px, 140, str(lv['flat']), 80, '#FFFFFF', weight='bold', anchor='middle')
               + C(px - 100, 112, 7, '#B8B2A2', stroke=o, stroke_width=2) + C(px + 100, 112, 7, '#B8B2A2', stroke=o, stroke_width=2), filter='url(#dsh)'))
    s.append(G(R(px - 150, 216, 300, 76, '#F4EEDC', rx=4, stroke='#B9AF98', stroke_width=2) + T(px, 266, lv['name'], 42, '#1D3A8F', font=HAND, anchor='middle')
               + R(px - 36, 204, 72, 26, '#E6DDB4', opacity='.85'), filter='url(#dsh)', transform='rotate(-3 %s 254)' % n(px)))
    cnt = [R(px - 140, 326, 280, 150, Q['plate'], rx=14, stroke='#8E6819', stroke_width=4)]
    for i, ch in enumerate('%03d' % moves):
        bx = px - 105 + i * 74
        cnt += [R(bx, 346, 62, 78, '#F4EEDC', rx=6, stroke=o, stroke_width=2), Ln(bx + 2, 385, bx + 60, 385, '#000000', 1.5, opacity='.25'),
                T(bx + 31, 407, ch, 60, '#1B1B1B', weight='bold', anchor='middle')]
    cnt.append(T(px, 458, 'ХОДЫ', 26, Q['cream'], weight='bold', anchor='middle', letter_spacing='5'))
    s.append(G(''.join(cnt), filter='url(#dsh)'))
    act = [R(px - 140, 502, 280, 124, Q['plate'], rx=14, stroke='#8E6819', stroke_width=4), (headL((px - 62, 580), 'right', 76, True, False) if active == 'head' else heelL((px - 62, 566), 'right', 76, True, False)),
           T(px + 42, 560, 'ходит' if active == 'head' else 'ходят', 28, '#BFB6A2', anchor='middle'), T(px + 42, 600, 'голова' if active == 'head' else 'ноги', 36, Q['cream'], weight='bold', anchor='middle')]
    s.append(G(''.join(act), filter='url(#dsh)'))
    for i, k in enumerate(('undo', 'restart', 'hint', 'menu')):
        s.append(button2(k, 1920 - ox / 2, 170 + i * 150))
    return ''.join(s)


def toilet2(cx, cy, c, wet=False):
    o, s = Q['ol'], []
    s.append(R(cx - .44 * c, cy - .52 * c, .38 * c, .46 * c, 'url(#enam)', rx=.07 * c, stroke=o, stroke_width=c * .045))
    s.append(R(cx - .48 * c, cy - .58 * c, .46 * c, .10 * c, 'url(#enam)', rx=.04 * c, stroke=o, stroke_width=c * .04))
    s.append(E(cx - .25 * c, cy - .60 * c, .07 * c, .03 * c, 'url(#steelG)', stroke=o, stroke_width=c * .025))
    s.append(Pa(dd('M', cx - .12 * c, cy - .04 * c, 'L', cx + .54 * c, cy - .04 * c, 'Q', cx + .54 * c, cy + .26 * c, cx + .18 * c, cy + .30 * c,
                   'L', cx + .14 * c, cy + .50 * c, 'L', cx - .18 * c, cy + .50 * c, 'L', cx - .15 * c, cy + .22 * c, 'Q', cx - .20 * c, cy + .08 * c, cx - .12 * c, cy - .04 * c, 'Z'),
                'url(#enam)', stroke=o, stroke_width=c * .045, stroke_linejoin='round'))
    s.append(Pa(dd('M', cx + .44 * c, cy + .02 * c, 'Q', cx + .44 * c, cy + .20 * c, cx + .20 * c, cy + .24 * c), stroke='#FFFFFF', stroke_width=c * .03, stroke_linecap='round', opacity='.85'))
    s.append(R(cx - .14 * c, cy - .11 * c, .70 * c, .09 * c, '#2E2B28', rx=.045 * c, stroke=o, stroke_width=c * .035))
    s.append(Ln(cx - .06 * c, cy - .09 * c, cx + .44 * c, cy - .09 * c, '#6B6660', c * .018))
    if wet:
        s.append(Pa(dd('M', cx + .02 * c, cy - .16 * c, 'q', .09 * c, -.12 * c, .18 * c, 0, 't', .18 * c, 0), stroke=Q['water'], stroke_width=c * .045, stroke_linecap='round'))
    s.append(face2(cx + .20 * c, cy + .14 * c, c * .9, 'happy' if wet else 'grumpy', look=(-1, 0)))
    s.append(R(cx - .56 * c, cy - .12 * c, .14 * c, .16 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .035))
    return ''.join(s)


def sink2(cx, cy, c, wet=False):
    o, s = Q['ol'], []
    s.append(R(cx - .30 * c, cy + .06 * c, .80 * c, .44 * c, '#EFE8D7', rx=.03 * c, stroke=o, stroke_width=c * .04))
    s.append(R(cx - .24 * c, cy + .12 * c, .32 * c, .32 * c, 'none', rx=.02 * c, stroke='#B9AF98', stroke_width=c * .02))
    s.append(R(cx + .14 * c, cy + .12 * c, .30 * c, .32 * c, 'none', rx=.02 * c, stroke='#B9AF98', stroke_width=c * .02))
    s.append(C(cx + .20 * c, cy + .28 * c, .022 * c, 'url(#steelG)', stroke=o, stroke_width=c * .015))
    for px, a, k in ((-.14, -20, 0), (.00, 10, 1), (.14, -8, 2)):
        s.append(E(cx + px * c, cy - .15 * c - k * .02 * c, .13 * c, .05 * c, 'url(#enam)', stroke=o, stroke_width=c * .025,
                   transform='rotate(%d %s %s)' % (a, n(cx + px * c), n(cy - .15 * c - k * .02 * c))))
    tap = dd('M', cx + .36 * c, cy - .08 * c, 'L', cx + .36 * c, cy - .40 * c, 'Q', cx + .36 * c, cy - .52 * c, cx + .24 * c, cy - .52 * c, 'L', cx + .12 * c, cy - .52 * c, 'L', cx + .12 * c, cy - .44 * c)
    s.append(Pa(tap, stroke=o, stroke_width=c * .10, stroke_linecap='round', stroke_linejoin='round'))
    s.append(Pa(tap, stroke='#C9D0D7', stroke_width=c * .06, stroke_linecap='round', stroke_linejoin='round'))
    s.append(G(Pa(tap, stroke='#FFFFFF', stroke_width=c * .018, stroke_linecap='round', stroke_linejoin='round', opacity='.8'), transform='translate(%s %s)' % (n(-.012 * c), n(-.012 * c))))
    if wet:
        s.append(Ln(cx + .12 * c, cy - .42 * c, cx + .12 * c, cy - .08 * c, Q['water'], c * .05))
        s.append(Ln(cx + .12 * c, cy - .42 * c, cx + .12 * c, cy - .08 * c, '#BDF3FF', c * .015))
    s.append(Pa(dd('M', cx - .38 * c, cy - .10 * c, 'L', cx + .50 * c, cy - .10 * c, 'L', cx + .44 * c, cy + .08 * c, 'L', cx - .32 * c, cy + .08 * c, 'Z'),
                'url(#steelG)', stroke=o, stroke_width=c * .04, stroke_linejoin='round'))
    s.append(Ln(cx - .30 * c, cy - .07 * c, cx + .40 * c, cy - .07 * c, '#FFFFFF', c * .02, opacity='.85'))
    s.append(face2(cx - .07 * c, cy + .27 * c, c * .85, 'happy' if wet else 'grumpy', look=(-1, 0)))
    s.append(R(cx - .56 * c, cy - .08 * c, .20 * c, .14 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .035))
    return ''.join(s)


def porcelain2(cx, cy, c):
    o, s = Q['ol'], []
    s.append(R(cx - .42 * c, cy - .28 * c, .84 * c, .74 * c, 'url(#enam)', rx=.12 * c, stroke=o, stroke_width=c * .045))
    s.append(R(cx - .46 * c, cy - .42 * c, .92 * c, .16 * c, 'url(#enam)', rx=.07 * c, stroke=o, stroke_width=c * .04))
    s.append(E(cx + .20 * c, cy - .44 * c, .08 * c, .035 * c, 'url(#steelG)', stroke=o, stroke_width=c * .025))
    for yy in (cy - .04 * c, cy + .22 * c):
        s.append(Ln(cx - .34 * c, yy, cx + .34 * c, yy, '#2F5E9E', c * .022))
    for i in range(5):
        fx, fy = cx - .28 * c + i * .14 * c, cy + .09 * c
        for a in (0, 90):
            s.append(E(fx, fy, .045 * c, .018 * c, '#2F5E9E', transform='rotate(%d %s %s)' % (a + 45, n(fx), n(fy))))
        s.append(C(fx, fy, .014 * c, '#FFFFFF'))
    s.append(E(cx - .22 * c, cy - .12 * c, .11 * c, .05 * c, '#FFFFFF', opacity='.9', transform='rotate(-20 %s %s)' % (n(cx - .22 * c), n(cy - .12 * c))))
    return ''.join(s)


def plug2(cx, cy, c, dr, th):
    """Заглушка (кв. 5): шестигранная головка и резьбовой хвостовик в сторону порта."""
    o, s = Q['ol'], []
    s.append(orient(R(cx - .02 * c, cy - .15 * c, .20 * c, .30 * c, 'url(#cylG)', stroke=o, stroke_width=c * .04), dr, cx, cy))
    hx = [(cx + .27 * c * math.cos(math.pi / 6 + k * math.pi / 3), cy + .27 * c * math.sin(math.pi / 6 + k * math.pi / 3)) for k in range(6)]
    s.append(Pg(hx, 'url(#nutG)', stroke=o, stroke_width=c * .045, stroke_linejoin='round'))
    s.append(C(cx, cy, .15 * c, 'url(#cylG)', stroke=o, stroke_width=c * .03))
    s.append(Ln(cx - .08 * c, cy, cx + .08 * c, cy, '#6E500F', c * .045))
    s.append(E(cx - .10 * c, cy - .13 * c, .07 * c, .035 * c, '#FFF3C9', opacity='.85', transform='rotate(-30 %s %s)' % (n(cx - .10 * c), n(cy - .13 * c))))
    s.append(port2(cx, cy, c, dr, th))
    return ''.join(s)


def fitting2(cx, cy, c, ports):
    o, s = Q['ol'], []
    ds = list(ports)
    if len(ds) == 1:
        return plug2(cx, cy, c, ds[0], ports[ds[0]])
    for dr in ds:
        s.append(orient(R(cx - .02 * c, cy - .17 * c, .22 * c, .34 * c, 'url(#cylG)', stroke=o, stroke_width=c * .04), dr, cx, cy))
    if len(ds) == 2 and OPP[ds[0]] == ds[1]:
        s.append(orient(R(cx - .12 * c, cy - .26 * c, .24 * c, .52 * c, 'url(#nutG)', rx=.05 * c, stroke=o, stroke_width=c * .04), ds[0], cx, cy))
    else:
        s.append(C(cx, cy, .25 * c, 'url(#cylG)', stroke=o, stroke_width=c * .04))
        s.append(E(cx - .08 * c, cy - .09 * c, .08 * c, .05 * c, '#FFF3C9', opacity='.8'))
    for dr, th in ports.items():
        s.append(port2(cx, cy, c, dr, th))
    return ''.join(s)


def pipe2(cx, cy, c, ports):
    """Закреплённая труба сети с несколькими выходами (темнее, как всё закреплённое)."""
    o, s = Q['ol'], []
    ds = list(ports)
    for dr in ds:
        s.append(orient(R(cx - .02 * c, cy - .18 * c, .30 * c, .36 * c, 'url(#ironH)', stroke=o, stroke_width=c * .04), dr, cx, cy))
    if not (len(ds) == 2 and OPP[ds[0]] == ds[1]):
        s.append(C(cx, cy, .24 * c, 'url(#ironH)', stroke=o, stroke_width=c * .04))
    s.append(C(cx - .07 * c, cy - .07 * c, .04 * c, '#C9CFD6', stroke=o, stroke_width=c * .015))
    for dr, th in ports.items():
        s.append(port2(cx, cy, c, dr, th, fixed=True))
    return ''.join(s)


def dryer2(cx, cy, c, wet=False, socks=0):
    """Полотенцесушитель (кв. 5): хромированная лесенка на стене; лицо между перекладинами.
    socks: 1 — один носок на верхней перекладине (для немой сцены)."""
    o, s, bx = Q['ol'], [], cx + .12 * c
    top, bot, xr = cy - .66 * c, cy + .56 * c, .30 * c
    for yy in (top + .16 * c, bot - .16 * c):
        s.append(R(bx + xr, yy - .05 * c, .30 * c, .10 * c, 'url(#ironH)', stroke=o, stroke_width=c * .03))
        s.append(R(bx + xr + .24 * c, yy - .11 * c, .08 * c, .22 * c, '#8A9097', rx=.02 * c, stroke=o, stroke_width=c * .025))
    for yy in (top + .08 * c, cy + .12 * c, cy + .30 * c, bot - .10 * c):
        s.append(R(bx - xr, yy - .045 * c, 2 * xr, .09 * c, 'url(#steelG)', rx=.045 * c, stroke=o, stroke_width=c * .03))
        s.append(Ln(bx - xr + .04 * c, yy - .02 * c, bx + xr - .04 * c, yy - .02 * c, '#FFFFFF', c * .018, opacity='.8'))
    for sx in (-1, 1):
        x = bx + sx * xr
        s.append(R(x - .055 * c, top, .11 * c, bot - top, 'url(#steelG)', rx=.055 * c, stroke=o, stroke_width=c * .035))
        s.append(Ln(x - .02 * c, top + .06 * c, x - .02 * c, bot - .06 * c, '#FFFFFF', c * .02, opacity='.85'))
        s.append(E(x, top, .07 * c, .035 * c, '#DCE2E8', stroke=o, stroke_width=c * .025))
    s.append(R(bx - xr + .06 * c, cy - .44 * c, 2 * xr - .12 * c, .44 * c, 'url(#enam)', rx=.08 * c, stroke=o, stroke_width=c * .03))
    s.append(face2(bx, cy - .26 * c, c * .82, 'happy' if wet else 'grumpy', look=(-1, 0)))
    if wet:
        for k, dx in enumerate((-.16, .02, .20)):
            x0 = bx + dx * c
            s.append(Pa(dd('M', x0, top - .06 * c, 'q', -.06 * c, -.08 * c, 0, -.16 * c, 't', 0, -.16 * c), stroke='#FFFFFF', stroke_width=c * .03,
                        stroke_linecap='round', opacity='%.2f' % (.85 - k * .12)))
    if socks:
        sx0, sy0 = bx - .12 * c, cy + .12 * c
        sock = dd('M', sx0 - .07 * c, sy0, 'L', sx0 - .07 * c, sy0 + .30 * c, 'Q', sx0 - .07 * c, sy0 + .40 * c, sx0 + .06 * c, sy0 + .40 * c,
                  'L', sx0 + .16 * c, sy0 + .40 * c, 'Q', sx0 + .22 * c, sy0 + .40 * c, sx0 + .22 * c, sy0 + .33 * c, 'Q', sx0 + .22 * c, sy0 + .27 * c,
                  sx0 + .12 * c, sy0 + .26 * c, 'L', sx0 + .07 * c, sy0 + .26 * c, 'L', sx0 + .07 * c, sy0, 'Z')
        s.append(Pa(sock, '#C0413A', stroke=o, stroke_width=c * .03, stroke_linejoin='round'))
        for k in range(3):
            yy = sy0 + (.05 + k * .08) * c
            s.append(Ln(sx0 - .07 * c, yy, sx0 + .07 * c, yy, '#F4EEDC', c * .03))
        s.append(R(sx0 - .09 * c, sy0 - .05 * c, .18 * c, .07 * c, '#C0413A', rx=.02 * c, stroke=o, stroke_width=c * .025))
    s.append(R(cx - .24 * c, cy - .10 * c, bx - xr - cx + .26 * c, .16 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .035))
    return ''.join(s)


def washer2(cx, cy, c, wet=False):
    """Стиральная машина (кв. 4): лицо над иллюминатором, иллюминатор — рот."""
    o, s, bx = Q['ol'], [], cx + .08 * c
    s.append(R(bx - .40 * c, cy - .48 * c, .84 * c, .98 * c, 'url(#enam)', rx=.08 * c, stroke=o, stroke_width=c * .045))
    s.append(R(bx - .34 * c, cy - .42 * c, .72 * c, .16 * c, '#DCE2E8', rx=.04 * c, stroke=o, stroke_width=c * .025))
    for kx in (.20, .30):
        s.append(C(bx + kx * c, cy - .34 * c, .045 * c, 'url(#steelG)', stroke=o, stroke_width=c * .02))
    s.append(C(bx, cy + .14 * c, .27 * c, 'url(#steelG)', stroke=o, stroke_width=c * .04))
    s.append(C(bx, cy + .14 * c, .20 * c, '#8FD4F0' if wet else '#2E3A44', stroke=o, stroke_width=c * .03))
    if wet:
        s.append(Pa(dd('M', bx - .19 * c, cy + .14 * c, 'q', .09 * c, -.07 * c, .19 * c, 0, 't', .19 * c, 0), stroke='#FFFFFF', stroke_width=c * .03, stroke_linecap='round'))
        s += [C(bx + dx * c, cy + dy * c, r * c, '#FFFFFF', opacity='.9') for dx, dy, r in ((-.06, .22, .03), (.07, .25, .025), (.02, .08, .02))]
    else:
        s.append(E(bx - .07 * c, cy + .06 * c, .06 * c, .035 * c, '#FFFFFF', opacity='.35', transform='rotate(-30 %s %s)' % (n(bx - .07 * c), n(cy + .06 * c))))
    for sx in (-1, 1):
        ex, ey = bx + sx * .13 * c, cy - .16 * c
        if wet:
            s.append(Pa(dd('M', ex - .05 * c, ey + .01 * c, 'Q', ex, ey - .06 * c, ex + .05 * c, ey + .01 * c), stroke=o, stroke_width=c * .03, stroke_linecap='round'))
        else:
            s.append(E(ex, ey, .05 * c, .055 * c, '#FFFFFF', stroke=o, stroke_width=c * .025))
            s.append(C(ex - .012 * c, ey + .01 * c, .025 * c, o))
            s.append(Ln(ex + sx * .06 * c, ey - .085 * c, ex - sx * .04 * c, ey - .06 * c, o, c * .03))
    s.append(R(cx - .56 * c, cy - .10 * c, .20 * c, .15 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .035))
    return ''.join(s)


def heater2(cx, cy, c, wet=False, big=False):
    """Газовая колонка (кв. 6): эмалевый короб на стене, дымоход уходит в потолок, вода входит снизу.
    Глазок горелки — рот: без воды пустой и в инее, под коробом сосульки; с водой в глазке синее пламя.
    big — для немой сцены: дымоход короче, без подводки к порту."""
    o, s = Q['ol'], []
    bw, top, bot = .40 * c, cy - .66 * c, cy + .14 * c
    # дымоход: алюминиевая гофра вверх, в потолок
    ft = cy - (.86 if big else 1.02) * c
    s.append(R(cx - .15 * c, ft, .30 * c, top - ft + .04 * c, 'url(#steelG)', stroke=o, stroke_width=c * .035))
    k = ft + .06 * c
    while k < top - .02 * c:
        s.append(Ln(cx - .15 * c, k, cx + .15 * c, k, '#7E8892', c * .018))
        s.append(Ln(cx - .12 * c, k + .025 * c, cx + .12 * c, k + .025 * c, '#FFFFFF', c * .012, opacity='.7'))
        k += .07 * c
    s.append(R(cx - .19 * c, top - .08 * c, .38 * c, .10 * c, 'url(#steelG)', rx=.03 * c, stroke=o, stroke_width=c * .03))
    # подводка воды снизу — к порту
    if not big:
        s.append(R(cx - .075 * c, bot - .04 * c, .15 * c, .22 * c, 'url(#cylGd)', stroke=o, stroke_width=c * .035))
    # излив горячей воды справа снизу
    s.append(Pa(dd('M', cx + bw - .04 * c, bot - .10 * c, 'L', cx + bw + .12 * c, bot - .10 * c, 'Q', cx + bw + .20 * c, bot - .10 * c, cx + bw + .20 * c, bot - .02 * c,
                   'L', cx + bw + .20 * c, bot + .06 * c), stroke=o, stroke_width=c * .085, stroke_linecap='round'))
    s.append(Pa(dd('M', cx + bw - .04 * c, bot - .10 * c, 'L', cx + bw + .12 * c, bot - .10 * c, 'Q', cx + bw + .20 * c, bot - .10 * c, cx + bw + .20 * c, bot - .02 * c,
                   'L', cx + bw + .20 * c, bot + .06 * c), stroke='#C9CFD6', stroke_width=c * .045, stroke_linecap='round'))
    # короб
    s.append(R(cx - bw, top, 2 * bw, bot - top, 'url(#enam)', rx=.09 * c, stroke=o, stroke_width=c * .045))
    s.append(Ln(cx - bw + .07 * c, top + .10 * c, cx - bw + .07 * c, bot - .26 * c, '#FFFFFF', c * .03, opacity='.9'))
    s.append(R(cx - bw + .05 * c, top + .05 * c, 2 * bw - .10 * c, .07 * c, '#DCE2E8', rx=.03 * c, opacity='.8'))
    # панель с ручкой внизу
    s.append(R(cx - bw + .04 * c, bot - .19 * c, 2 * bw - .08 * c, .15 * c, '#C8D0D8', rx=.03 * c, stroke=o, stroke_width=c * .025))
    s.append(C(cx + .22 * c, bot - .115 * c, .055 * c, '#2E3338', stroke=o, stroke_width=c * .02))
    s.append(Ln(cx + .22 * c, bot - .115 * c, cx + .22 * c + (.04 if wet else -.04) * c, bot - .16 * c, '#E8ECF0', c * .02))
    s.append(C(cx - .22 * c, bot - .115 * c, .03 * c, '#C83E2C' if wet else '#6B7178', stroke=o, stroke_width=c * .015))
    # глазок горелки — рот
    wx, wy, wr = cx, cy - .20 * c, .13 * c
    s.append(C(wx, wy, wr + .035 * c, 'url(#steelG)', stroke=o, stroke_width=c * .03))
    s.append(C(wx, wy, wr, '#16222C', stroke=o, stroke_width=c * .022))
    if wet:
        s.append(C(wx, wy + .02 * c, wr * .95, 'url(#glow)'))
        for dx, hgt, col in ((-.07, .15, '#2E7BF1'), (.07, .15, '#2E7BF1'), (0, .21, '#3FA2FF')):
            fx0, fb = wx + dx * c, wy + .09 * c
            s.append(Pa(dd('M', fx0 - .035 * c, fb, 'Q', fx0 - .03 * c, fb - hgt * .55 * c, fx0, fb - hgt * c, 'Q', fx0 + .03 * c, fb - hgt * .55 * c, fx0 + .035 * c, fb, 'Z'),
                        col, stroke='#0E2E6B', stroke_width=c * .008))
            s.append(Pa(dd('M', fx0 - .014 * c, fb, 'Q', fx0 - .01 * c, fb - hgt * .4 * c, fx0, fb - hgt * .62 * c, 'Q', fx0 + .01 * c, fb - hgt * .4 * c, fx0 + .014 * c, fb, 'Z'), '#BFEFFF'))
    else:
        for a in range(6):
            ang = a * math.pi / 3 + .3
            s.append(Ln(wx + math.cos(ang) * wr * .55, wy + math.sin(ang) * wr * .55, wx + math.cos(ang) * wr * .95, wy + math.sin(ang) * wr * .95, '#DDF3FF', c * .014, opacity='.8'))
        s.append(Pa(dd('M', wx - .07 * c, wy + .035 * c, 'Q', wx, wy - .02 * c, wx + .07 * c, wy + .035 * c), stroke='#DDF3FF', stroke_width=c * .018, stroke_linecap='round', opacity='.7'))
    # глаза над глазком
    for sx in (-1, 1):
        ex, ey = cx + sx * .14 * c, cy - .47 * c
        if wet:
            s.append(Pa(dd('M', ex - .06 * c, ey + .015 * c, 'Q', ex, ey - .06 * c, ex + .06 * c, ey + .015 * c), stroke=o, stroke_width=c * .03, stroke_linecap='round'))
        else:
            s.append(E(ex, ey, .06 * c, .065 * c, '#FFFFFF', stroke=o, stroke_width=c * .025))
            s.append(C(ex + sx * .012 * c, ey + .012 * c, .03 * c, o))
            s.append(Ln(ex + sx * .07 * c, ey - .11 * c, ex - sx * .05 * c, ey - .07 * c, o, c * .028))
    if wet:
        for k2, dx in enumerate((-.22, .02, .24)):
            x0 = cx + dx * c
            s.append(Pa(dd('M', x0, top - .10 * c, 'q', -.05 * c, -.07 * c, 0, -.14 * c, 't', 0, -.14 * c), stroke='#FFFFFF', stroke_width=c * .028,
                        stroke_linecap='round', opacity='%.2f' % (.8 - k2 * .12)))
    else:
        for x0, y0, ln in ((cx - .35 * c, bot - .01 * c, .14), (cx - .27 * c, bot - .01 * c, .09), (cx + bw + .20 * c, bot + .07 * c, .12)):
            s.append(Pa(dd('M', x0 - .028 * c, y0, 'L', x0, y0 + ln * c, 'L', x0 + .028 * c, y0, 'Z'), '#E6F7FF', stroke=o, stroke_width=c * .015,
                        stroke_linejoin='round'))
        sx_, sy_, sr = cx - .26 * c, top + .20 * c, .045 * c
        for a in range(3):
            ang = a * math.pi / 3
            s.append(Ln(sx_ - math.cos(ang) * sr, sy_ - math.sin(ang) * sr, sx_ + math.cos(ang) * sr, sy_ + math.sin(ang) * sr, '#9ED8F0', c * .012))
        s.append(Pa(dd('M', cx - bw + .02 * c, top + .03 * c, 'Q', cx, top - .04 * c, cx + bw - .02 * c, top + .03 * c), stroke='#F4FBFF', stroke_width=c * .03, stroke_linecap='round', opacity='.9'))
    return ''.join(s)


# ---------- кадр

def frame(lv, moves=0, active='head', no_lap=False, hud=True, skip=()):
    grid = lv['grid']
    H, W = len(grid), len(grid[0])
    c = min(120, 1920 // W, 1080 // H)
    ox, oy = (1920 - W * c) // 2, (1080 - H * c) // 2
    ml, mt = math.ceil(ox / c) + 1, math.ceil(oy / c) + 1

    def empty(x, y):
        if 1 <= x <= W and 1 <= y <= H:
            return grid[y - 1][x - 1] != '#'
        return 1 <= x <= W and H < y <= H + mt and grid[H - 1][x - 1] == '~'
    room_d = ' '.join(loop_d(simplify(lp), c, ox, oy, .20, .42) for lp in trace(empty, (1 - ml, W + ml), (1 - mt, H + mt)))
    terr_d = 'M -40 -40 H 1960 V 1120 H -40 Z ' + room_d
    extra = defs2(c, ox, oy, lv.get('tile', 'mint')) + ('<clipPath id="cRoom"><path d="%s" clip-rule="evenodd"/></clipPath>'
                                                        '<clipPath id="cTerr"><path d="%s" clip-rule="evenodd"/></clipPath>' % (room_d, terr_d))
    s = [room_paint(ox, oy, W, H, c),
         G(Pa(terr_d, '#000000', fill_rule='evenodd', opacity='.32', filter='url(#bl8)', transform='translate(%s %s)' % (n(.10 * c), n(.15 * c))), clip_path='url(#cRoom)'),
         G(Pa(room_d, stroke='#000000', stroke_width=.6 * c, opacity='.22', filter='url(#bl18)'), clip_path='url(#cRoom)'),
         Pa(terr_d, 'url(#concG)', fill_rule='evenodd'),
         G(Pa(room_d, stroke='url(#tiles)', stroke_width=1.0 * c, stroke_linejoin='round'), clip_path='url(#cTerr)'),
         Pa(terr_d, '#000000', fill_rule='evenodd', filter='url(#grain)', opacity='.4'),
         G(Pa(room_d, stroke='#FFF7E2', stroke_width=.05 * c, opacity='.8', transform='translate(0 %s)' % n(.05 * c)), clip_path='url(#cTerr)')]
    for y in range(1, H + 1):
        for x in range(1, W + 1):
            if grid[y - 1][x - 1] == '~':
                s.append(drain2(ox + (x - .5) * c, oy + (y - .5) * c, c))
    s.append(Pa(room_d, stroke=Q['ol'], stroke_width=.08 * c, stroke_linejoin='round', filter='url(#wob)'))
    wl = lambda x, y: 1 <= x <= W and 1 <= y <= H and grid[y - 1][x - 1] == '#'

    def ext(x, y, dy):
        yy = y + dy
        while 1 <= yy <= H and grid[yy - 1][x - 1] == '#':
            yy += dy
        if yy < 1 or yy > H:
            return -20 if dy < 0 else 1100
        return oy + yy * c if dy < 0 else oy + (yy - 1) * c
    lap = None
    for ob in lv['objects']:
        k = ob['kind']
        if k == 'lapidus':
            lap = ob
            continue
        if k in skip:
            continue
        x, y = ob['at']
        cx, cy = ox + (x - .5) * c, oy + (y - .5) * c
        ports = ob.get('ports', {})
        if k == 'source':
            s.append(G(source2(cx, cy, c, ports, ext(x, y, -1), ext(x, y, 1), lv.get('pressure', 0) or 0), filter='url(#dsh)'))
        elif k == 'fixture':
            pd, th = list(ports.items())[0]
            body = {'bath': bath2, 'toilet': toilet2, 'sink': sink2, 'washer': washer2, 'dryer': dryer2, 'heater': heater2}.get(ob.get('what'), bath2)(cx, cy, c)
            if pd == 'right':
                body = G(body, transform='translate(%s 0) scale(-1 1)' % n(2 * cx))
            s.append(G(body + port2(cx, cy - .02 * c, c, pd, th, True), filter='url(#dsh)'))
        elif k == 'stub':
            pd, th = list(ports.items())[0]
            cand = [OPP[pd]] + [m for m in ('left', 'right', 'up', 'down') if m not in (pd, OPP[pd])]
            mount = next((m for m in cand if wl(x + DV[m][0], y + DV[m][1])), OPP[pd])
            s.append(G(stub2(cx, cy, c, pd, th, mount), filter='url(#dsh)'))
        elif k == 'pipe':
            s.append(G(pipe2(cx, cy, c, ports), filter='url(#dsh)'))
        elif k == 'porcelain':
            s.append(G(porcelain2(cx, cy, c), filter='url(#dsh)'))
        elif k == 'fitting':
            s.append(G(fitting2(cx, cy, c, ports), filter='url(#dsh)'))
    if lap and not no_lap:
        Lr = lv.get('length', [2, 4])
        s.append(hero([(ox + (x - .5) * c, oy + (y - .5) * c) for x, y in lap['cells']], c, Lr[0], Lr[1], active))
    if hud:
        s.append(hud2(lv, ox, moves, active))
    return ''.join(s), extra, (c, ox, oy)


def headFront(pt, c, active, screwed):
    """Голова анфас — когда Лапидус кусает вниз: рот-гнездо внизу по центру."""
    cx, cy = pt
    o, hair, s = Q['ol'], '#2A1D17', []
    s.append(R(cx - .19 * c, cy - .52 * c, .38 * c, .14 * c, 'url(#nutG)', rx=.04 * c, stroke=o, stroke_width=c * .04))
    for sx in (-1, 1):
        s.append(E(cx + sx * .35 * c, cy - .04 * c, .075 * c, .10 * c, 'url(#skinG)', stroke=o, stroke_width=c * .035))
    head = [(cx, cy - .10 * c, .35 * c, .34 * c), (cx, cy + .10 * c, .30 * c, .22 * c)]
    for x, y, rx, ry in head:
        s.append(E(x, y, rx, ry, o, stroke=o, stroke_width=c * .09))
    for x, y, rx, ry in head:
        s.append(E(x, y, rx, ry, 'url(#skinG)'))
    s.append(E(cx, cy + .16 * c, .24 * c, .12 * c, '#4E6078', opacity='.2'))
    for sx in (-1, 1):
        s.append(Pa(dd('M', cx + sx * .16 * c, cy - .36 * c, 'Q', cx + sx * .40 * c, cy - .30 * c, cx + sx * .36 * c, cy + .02 * c,
                       'L', cx + sx * .27 * c, cy + .02 * c, 'Q', cx + sx * .30 * c, cy - .22 * c, cx + sx * .12 * c, cy - .30 * c, 'Z'),
                    hair, stroke=o, stroke_width=c * .03, stroke_linejoin='round'))
    for k in range(3):
        s.append(Pa(dd('M', cx - .20 * c, cy - .33 * c - k * .03 * c, 'Q', cx, cy - .47 * c - k * .02 * c, cx + .20 * c, cy - .33 * c - k * .03 * c), stroke=hair, stroke_width=c * .018, stroke_linecap='round'))
    s.append(E(cx - .10 * c, cy - .34 * c, .10 * c, .04 * c, '#FFFFFF', opacity='.6', transform='rotate(-15 %s %s)' % (n(cx - .10 * c), n(cy - .34 * c))))
    foam = ((-.08, -.46, .09), (.08, -.49, .10), (.20, -.41, .075))
    for fx, fy, fr in foam:
        s.append(C(cx + fx * c, cy + fy * c, fr * c + .02 * c, o))
    for fx, fy, fr in foam:
        s.append(C(cx + fx * c, cy + fy * c, fr * c, '#FFFFFF'))
        s.append(C(cx + fx * c + fr * c * .3, cy + fy * c + fr * c * .35, fr * c * .45, Q['foam_sh'], opacity='.65'))
    for sx in (-1, 1):
        s.append(Pa(dd('M', cx + sx * .04 * c, cy - .24 * c, 'Q', cx + sx * .13 * c, cy - .31 * c, cx + sx * .22 * c, cy - .23 * c), stroke=hair, stroke_width=c * .055, stroke_linecap='round'))
        ex, ey = cx + sx * .12 * c, cy - .13 * c
        if active:
            s.append(E(ex, ey, .075 * c, .09 * c, '#FFFFFF', stroke=o, stroke_width=c * .03))
            s.append(C(ex, ey + .03 * c, .034 * c, o))
            s.append(C(ex - .012 * c, ey + .018 * c, .011 * c, '#FFFFFF'))
        else:
            s.append(E(ex, ey, .075 * c, .09 * c, 'url(#skinG)', stroke=o, stroke_width=c * .03))
            s.append(Pa(dd('M', ex - .06 * c, ey + .01 * c, 'Q', ex, ey + .05 * c, ex + .06 * c, ey + .01 * c), stroke=o, stroke_width=c * .03, stroke_linecap='round'))
    s.append(E(cx, cy + .02 * c, .10 * c, .085 * c, '#ECA88A', stroke=o, stroke_width=c * .035))
    s.append(E(cx - .03 * c, cy - .01 * c, .03 * c, .02 * c, '#FFFFFF', opacity='.7'))
    mus = dd('M', cx, cy + .09 * c, 'Q', cx - .12 * c, cy + .05 * c, cx - .20 * c, cy + .10 * c, 'Q', cx - .30 * c, cy + .15 * c, cx - .28 * c, cy + .24 * c,
             'Q', cx - .20 * c, cy + .17 * c, cx - .10 * c, cy + .19 * c, 'Q', cx, cy + .21 * c, cx + .10 * c, cy + .19 * c,
             'Q', cx + .20 * c, cy + .17 * c, cx + .28 * c, cy + .24 * c, 'Q', cx + .30 * c, cy + .15 * c, cx + .20 * c, cy + .10 * c,
             'Q', cx + .12 * c, cy + .05 * c, cx, cy + .09 * c, 'Z')
    s.append(Pa(mus, hair, stroke=o, stroke_width=c * .03, stroke_linejoin='round'))
    s.append(E(cx, cy + .30 * c, .085 * c, .07 * c, 'url(#cylG)', stroke=o, stroke_width=c * .03))
    s.append(E(cx, cy + .31 * c, .05 * c, .04 * c, '#1A120C'))
    for k in (-.02, .02):
        s.append(Ln(cx + k * c, cy + .28 * c, cx + k * c, cy + .34 * c, '#B8913A', c * .013))
    if screwed:
        s.append(fluff2(cx - .06 * c, cy + .40 * c, c))
    return ''.join(s)


def headL(pt, dr, c, active, screwed):
    """Голова Лапидуса по канону серии: лысеющий усатый брюнет, на макушке мыльная пена;
    рот — латунное гнездо с внутренней резьбой (§2: вцепляется в трубу зубами)."""
    if dr == 'down':
        return headFront(pt, c, active, screwed)
    cx, cy = pt
    o, hair, s = Q['ol'], '#2A1D17', []
    s.append(R(cx - .46 * c, cy - .19 * c, .14 * c, .38 * c, 'url(#nutG)', rx=.04 * c, stroke=o, stroke_width=c * .04))
    head = [(cx - .04 * c, cy - .14 * c, .35 * c, .35 * c), (cx + .08 * c, cy + .07 * c, .31 * c, .21 * c)]
    for x, y, rx, ry in head:
        s.append(E(x, y, rx, ry, o, stroke=o, stroke_width=c * .09))
    for x, y, rx, ry in head:
        s.append(E(x, y, rx, ry, 'url(#skinG)'))
    s.append(E(cx + .15 * c, cy + .11 * c, .23 * c, .12 * c, '#4E6078', opacity='.2'))
    s.append(Pa(dd('M', cx - .10 * c, cy - .45 * c, 'Q', cx - .45 * c, cy - .40 * c, cx - .39 * c, cy - .07 * c, 'Q', cx - .36 * c, cy + .08 * c, cx - .24 * c, cy + .09 * c,
                   'L', cx - .19 * c, cy - .02 * c, 'Q', cx - .21 * c, cy - .12 * c, cx - .17 * c, cy - .18 * c, 'Q', cx - .26 * c, cy - .32 * c, cx - .07 * c, cy - .37 * c, 'Z'),
                hair, stroke=o, stroke_width=c * .03, stroke_linejoin='round'))
    s.append(E(cx - .27 * c, cy - .06 * c, .085 * c, .11 * c, 'url(#skinG)', stroke=o, stroke_width=c * .035))
    s.append(Pa(dd('M', cx - .24 * c, cy - .12 * c, 'Q', cx - .31 * c, cy - .06 * c, cx - .25 * c, cy + .01 * c), stroke='#B97D5E', stroke_width=c * .025, stroke_linecap='round'))
    for k in range(3):
        s.append(Pa(dd('M', cx - .22 * c + k * .03 * c, cy - .40 * c - k * .015 * c, 'Q', cx - .02 * c, cy - .55 * c + k * .025 * c, cx + .16 * c + k * .03 * c, cy - .45 * c + k * .02 * c),
                    stroke=hair, stroke_width=c * .018, stroke_linecap='round'))
    s.append(E(cx + .02 * c, cy - .38 * c, .11 * c, .045 * c, '#FFFFFF', opacity='.6', transform='rotate(-10 %s %s)' % (n(cx + .02 * c), n(cy - .38 * c))))
    foam = ((-.24, -.40, .085), (-.13, -.47, .095), (-.32, -.29, .07))
    for fx, fy, fr in foam:
        s.append(C(cx + fx * c, cy + fy * c, fr * c + .02 * c, o))
    for fx, fy, fr in foam:
        s.append(C(cx + fx * c, cy + fy * c, fr * c, '#FFFFFF'))
        s.append(C(cx + fx * c + fr * c * .3, cy + fy * c + fr * c * .35, fr * c * .45, Q['foam_sh'], opacity='.65'))
    for bx_, by_, br in ((-.02, -.58, .03), (.08, -.61, .02)):
        s.append(C(cx + bx_ * c, cy + by_ * c, br * c, '#FFFFFF', stroke=o, stroke_width=c * .012))
    for bd in (dd('M', cx - .03 * c, cy - .34 * c, 'Q', cx + .06 * c, cy - .41 * c, cx + .14 * c, cy - .35 * c),
               dd('M', cx + .18 * c, cy - .35 * c, 'Q', cx + .25 * c, cy - .40 * c, cx + .32 * c, cy - .33 * c)):
        s.append(Pa(bd, stroke=hair, stroke_width=c * .055, stroke_linecap='round'))
    for ex, ey, rx, ry in ((cx + .05 * c, cy - .24 * c, .075 * c, .09 * c), (cx + .235 * c, cy - .24 * c, .065 * c, .082 * c)):
        if active:
            s.append(E(ex, ey, rx, ry, '#FFFFFF', stroke=o, stroke_width=c * .03))
            s.append(C(ex + .028 * c, ey + .012 * c, .034 * c, o))
            s.append(C(ex + .016 * c, ey, .011 * c, '#FFFFFF'))
        else:
            s.append(E(ex, ey, rx, ry, 'url(#skinG)', stroke=o, stroke_width=c * .03))
            s.append(Pa(dd('M', ex - rx * .8, ey + .01 * c, 'Q', ex, ey + .05 * c, ex + rx * .8, ey + .01 * c), stroke=o, stroke_width=c * .03, stroke_linecap='round'))
    s.append(E(cx + .37 * c, cy - .10 * c, .13 * c, .10 * c, '#ECA88A', stroke=o, stroke_width=c * .035))
    s.append(E(cx + .34 * c, cy - .14 * c, .035 * c, .022 * c, '#FFFFFF', opacity='.7'))
    mus = dd('M', cx + .12 * c, cy + .03 * c, 'Q', cx + .20 * c, cy - .07 * c, cx + .31 * c, cy - .02 * c, 'Q', cx + .42 * c, cy - .07 * c, cx + .53 * c, cy + .03 * c,
             'Q', cx + .51 * c, cy + .13 * c, cx + .42 * c, cy + .08 * c, 'Q', cx + .33 * c, cy + .12 * c, cx + .26 * c, cy + .08 * c,
             'Q', cx + .17 * c, cy + .13 * c, cx + .12 * c, cy + .03 * c, 'Z')
    s.append(Pa(mus, hair, stroke=o, stroke_width=c * .03, stroke_linejoin='round'))
    s.append(Pa(dd('M', cx + .18 * c, cy, 'Q', cx + .30 * c, cy - .03 * c, cx + .45 * c, cy), stroke='#6A5244', stroke_width=c * .018, stroke_linecap='round'))
    s.append(E(cx + .42 * c, cy + .16 * c, .075 * c, .07 * c, 'url(#cylG)', stroke=o, stroke_width=c * .03))
    s.append(E(cx + .43 * c, cy + .16 * c, .045 * c, .042 * c, '#1A120C'))
    for k in (-.018, .018):
        s.append(Ln(cx + .40 * c, cy + .16 * c + k * c, cx + .46 * c, cy + .16 * c + k * c, '#B8913A', c * .013))
    if screwed:
        s.append(fluff2(cx + .47 * c, cy + .10 * c, c))
    return orient(''.join(s), dr, cx, cy)


def heelL(pt, dr, c, active, screwed):
    """Ноги: латунный штуцер с наружной резьбой и пальцами ног (брюнет — с волосками)."""
    cx, cy = pt
    o, s = Q['ol'], []
    toes = ((-.21, .05, .075), (-.13, .044, .064), (-.06, .04, .058), (.005, .036, .052), (.06, .032, .046))
    for i, (tx, rx, ry) in enumerate(toes):
        x = cx + tx * c
        if active:
            y = cy + .34 * c + ry * c * .5
            s.append(E(x, y, rx * c, ry * c, Q['skin'], stroke=o, stroke_width=c * .026, transform='rotate(%d %s %s)' % ((i - 2) * 9, n(x), n(y))))
            s.append(E(x, y + ry * c * .5, rx * c * .5, ry * c * .22, '#FFE9DE'))
        else:
            s.append(E(x + .01 * c, cy + .30 * c, rx * c * .9, rx * c * .9, Q['skin'], stroke=o, stroke_width=c * .026))
    for k in range(3):
        x0 = cx - .235 * c + k * .022 * c
        s.append(Ln(x0, cy + .33 * c, x0 - .012 * c, cy + .295 * c, '#2A1D17', c * .011))
    s.append(R(cx - .24 * c, cy - .31 * c, .26 * c, .62 * c, 'url(#nutG)', rx=.07 * c, stroke=o, stroke_width=c * .045))
    s.append(R(cx + .01 * c, cy - .20 * c, .45 * c, .40 * c, 'url(#cylG)', rx=.08 * c, stroke=o, stroke_width=c * .04))
    for i in range(5):
        x = cx + .08 * c + i * .07 * c
        s.append(Ln(x, cy - .185 * c, x + .05 * c, cy + .185 * c, '#5E4410', c * .028))
        s.append(Ln(x + .025 * c, cy - .17 * c, x + .065 * c, cy + .12 * c, '#FBE7A6', c * .013, opacity='.8'))
    if screwed:
        s.append(fluff2(cx + .47 * c, cy, c))
    return orient(''.join(s), dr, cx, cy)


def main():
    L = json.loads(subprocess.check_output(['luajit', 'tools/dumplevels.lua', '1'], cwd=ROOT).decode('utf-8'))
    body, extra, _ = frame(L[0])
    svg = os.path.join(OUT, 's1_level1.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080"><defs>%s</defs>%s</svg>' % (extra, body))
    subprocess.run(['rsvg-convert', '-w', '1920', '-h', '1080', '-o', os.path.join(OUT, 's1_level1.png'), svg], check=True)
    subprocess.run(['rsvg-convert', '-w', '3840', '-h', '2160', '-o', '/tmp/s1_2x.png', svg], check=True)
    print('ok')


if __name__ == '__main__':
    main()
