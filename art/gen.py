#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/gen.py — SVG-генераторы арта «Лапидус. Ни капли» (§8 дизайн-документа).

Всё нарисовано кодом: заливка, одна тень, один блик, контур #2B2118 (cel-shading), палитра §8.
Выход — build/review/*.png, макеты для визуального согласования. На фазе 3 эти же функции
режут PNG-атласы для игры. Текст в макетах набран шрифтами движка: PT Sans Narrow и Neucha."""
import json, math, os, subprocess, traceback

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'build', 'review')
os.makedirs(OUT, exist_ok=True)

P = dict(ol='#2B2118', brass='#C99A2E', hi='#F6DB8A', sh='#7A5A14',
         hose='#F2EFE6', hose_sh='#CCC4AF', rib='#948972', porc='#FBFBF8', cobalt='#2F5E9E',
         water='#2EC4F1', water_dk='#1480B3', water_lt='#B7F1FF', foam='#FFFFFF', foam_sh='#C8DDE8',
         paint='#5B7B6C', wash='#D2D8D3', stripe='#6A4434', paper='#F3EDDC', ink='#23304E',
         stamp='#2B56B8', red='#C73E2E', skin='#EDB798', steel='#AEB7C0', cream='#F4EEDC',
         ok='#2E8B57', bad='#C0392B')
TILE = {'mint': ('#B4D7C2', '#83AA94', '#E4F3EA'), 'blue': ('#B2C9E1', '#819DBF', '#E5EEF8'),
        'mustard': ('#DFC57F', '#B1934A', '#F4E9C3')}
UI, HAND = 'PT Sans Narrow', 'Neucha'
# без шрифтов игры в системе rsvg молча подставляет широкий DejaVu, и текст в арте вылезает за рамки
if not all(f in subprocess.run(['fc-list'], capture_output=True, text=True).stdout for f in (UI, HAND)):
    raise SystemExit('нет шрифтов %s / %s в системе: bash tools/setup_sandbox.sh' % (UI, HAND))
DV = {'up': (0, -1), 'right': (1, 0), 'down': (0, 1), 'left': (-1, 0)}
ANG = {'right': 0, 'down': 90, 'left': 180, 'up': -90}
OPP = {'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}


def n(v):
    s = '%.1f' % v
    return s[:-2] if s.endswith('.0') else s


def at(**kw):
    out = []
    for k, v in kw.items():
        if v is None:
            continue
        if isinstance(v, float):
            v = n(v)
        out.append(' %s="%s"' % (k.rstrip('_').replace('_', '-'), v))
    return ''.join(out)


def R(x, y, w, h, fill, rx=0, **kw):
    return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s/>' % (n(x), n(y), n(w), n(h), n(rx), fill, at(**kw))


def C(x, y, r, fill, **kw):
    return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>' % (n(x), n(y), n(r), fill, at(**kw))


def E(x, y, rx, ry, fill, **kw):
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s/>' % (n(x), n(y), n(rx), n(ry), fill, at(**kw))


def Ln(x1, y1, x2, y2, col, w, **kw):
    return '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"%s/>' % (
        n(x1), n(y1), n(x2), n(y2), col, n(w), at(**kw))


def Pg(pts, fill, **kw):
    return '<polygon points="%s" fill="%s"%s/>' % (' '.join('%s,%s' % (n(a), n(b)) for a, b in pts), fill, at(**kw))


def Pa(d, fill='none', **kw):
    return '<path d="%s" fill="%s"%s/>' % (d, fill, at(**kw))


def G(body, **kw):
    return '<g%s>%s</g>' % (at(**kw), body)


def rot(body, a, x, y):
    return body if not a else '<g transform="rotate(%s %s %s)">%s</g>' % (n(a), n(x), n(y), body)


def T(x, y, s, size, fill, font=UI, weight='normal', anchor='start', **kw):
    s = s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    return '<text x="%s" y="%s" font-family="%s" font-size="%s" font-weight="%s" text-anchor="%s" fill="%s"%s>%s</text>' % (
        n(x), n(y), font, n(size), weight, anchor, fill, at(**kw), s)


def dd(*parts):
    return ' '.join(n(p) if isinstance(p, (int, float)) else str(p) for p in parts)


def wrap(text, width):
    lines, cur = [], ''
    for w in text.split():
        if cur and len(cur) + 1 + len(w) > width:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + ' ' + w) if cur else w
    if cur:
        lines.append(cur)
    return lines


DEFS = (
    '<linearGradient id="br" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6DB8A"/><stop offset=".45" stop-color="#C99A2E"/><stop offset="1" stop-color="#7A5A14"/></linearGradient>'
    '<linearGradient id="brF" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DDBF72"/><stop offset=".45" stop-color="#A57C25"/><stop offset="1" stop-color="#5C430F"/></linearGradient>'
    '<linearGradient id="brL" gradientUnits="userSpaceOnUse" x1="0" y1="-12" x2="0" y2="162"><stop offset="0" stop-color="#F6DB8A"/><stop offset=".5" stop-color="#C99A2E"/><stop offset="1" stop-color="#7A5A14"/></linearGradient>'
    '<linearGradient id="ir" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2E3338"/><stop offset=".3" stop-color="#8A939E"/><stop offset=".6" stop-color="#58606A"/><stop offset="1" stop-color="#2A2E33"/></linearGradient>'
    '<linearGradient id="irV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2E3338"/><stop offset=".3" stop-color="#8A939E"/><stop offset=".6" stop-color="#58606A"/><stop offset="1" stop-color="#2A2E33"/></linearGradient>'
    '<linearGradient id="pc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".65" stop-color="#FBFBF8"/><stop offset="1" stop-color="#CDD3DB"/></linearGradient>'
    '<linearGradient id="st" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EEF2F6"/><stop offset="1" stop-color="#8C96A0"/></linearGradient>'
    '<linearGradient id="wt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FE3FA"/><stop offset="1" stop-color="#1480B3"/></linearGradient>'
    '<radialGradient id="vg" cx=".5" cy=".45" r=".75"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".38"/></radialGradient>'
    '<radialGradient id="warm" cx=".5" cy=".35" r=".8"><stop offset="0" stop-color="#FFE9AE"/><stop offset="1" stop-color="#E4A14A"/></radialGradient>'
    '<radialGradient id="bulb" cx=".5" cy="0" r="1"><stop offset="0" stop-color="#FFE9A8" stop-opacity=".45"/><stop offset="1" stop-color="#FFE9A8" stop-opacity="0"/></radialGradient>'
    '<linearGradient id="bsm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A332D"/><stop offset="1" stop-color="#15120F"/></linearGradient>'
    '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1F2B44"/><stop offset="1" stop-color="#5C6E8C"/></linearGradient>'
    '<linearGradient id="stair" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2A3136"/><stop offset="1" stop-color="#161A1D"/></linearGradient>'
    '<filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="8" result="b"/><feOffset in="b" dy="8" result="o"/>'
    '<feComponentTransfer in="o" result="s"><feFuncA type="linear" slope=".5"/></feComponentTransfer><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter>')


def render(name, w, h, body, extra=''):
    p = os.path.join(OUT, name + '.svg')
    with open(p, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>' % (w, h, w, h, DEFS, extra, body))
    subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), '-o', os.path.join(OUT, name + '.png'), p], check=True)


# ---------------------------------------------------------------- детали

def port(cx, cy, c, dr, th, fixed=False):
    o, lw, gr = P['ol'], c * .03, ('url(#brF)' if fixed else 'url(#br)')
    s = []
    if th == 'N':   # наружная резьба: торчащий штуцер с витками
        s.append(R(cx + .19 * c, cy - .21 * c, .11 * c, .42 * c, gr, rx=.02 * c, stroke=o, stroke_width=lw))
        s.append(R(cx + .29 * c, cy - .15 * c, .27 * c, .30 * c, gr, rx=.05 * c, stroke=o, stroke_width=lw))
        for i in range(4):
            x = cx + .33 * c + i * .055 * c
            s.append(Ln(x, cy - .135 * c, x + .035 * c, cy + .135 * c, P['sh'], c * .02))
    else:           # внутренняя резьба: утопленное шестигранное гнездо
        pts = [(.19, -.25), (.44, -.25), (.53, -.13), (.53, .13), (.44, .25), (.19, .25)]
        s.append(Pg([(cx + a * c, cy + b * c) for a, b in pts], gr, stroke=o, stroke_width=lw, stroke_linejoin='round'))
        s.append(Ln(cx + .28 * c, cy - .23 * c, cx + .28 * c, cy + .23 * c, P['sh'], c * .018))
        s.append(Ln(cx + .40 * c, cy - .23 * c, cx + .40 * c, cy + .23 * c, P['hi'], c * .018))
        s.append(R(cx + .455 * c, cy - .15 * c, .085 * c, .30 * c, '#1B140F', rx=.035 * c))
        s.append(Ln(cx + .495 * c, cy - .11 * c, cx + .495 * c, cy + .11 * c, '#7A6746', c * .013,
                    stroke_dasharray='%s %s' % (n(c * .03), n(c * .025))))
    return rot(''.join(s), ANG[dr], cx, cy)


def source(cx, cy, c, ports, up_wall, down_wall):
    o, lw, s = P['ol'], c * .03, []
    top = cy - .5 * c - (.46 * c if up_wall else 0)
    bot = cy + .5 * c + (.46 * c if down_wall else 0)
    s.append(R(cx - .19 * c, top, .38 * c, bot - top, 'url(#ir)', stroke=o, stroke_width=lw))
    s.append(Pa(dd('M', cx - .07 * c, cy - .40 * c, 'q', .03 * c, .25 * c, -.01 * c, .5 * c), stroke='#8B4A2B',
                stroke_width=c * .035, stroke_linecap='round', opacity='.55'))
    for yy in (cy - .46 * c, cy + .36 * c):
        s.append(R(cx - .23 * c, yy, .46 * c, .10 * c, 'url(#ir)', rx=.02 * c, stroke=o, stroke_width=lw))
    s.append(R(cx - .24 * c, cy - .31 * c, .48 * c, .07 * c, '#3A3F45', rx=.02 * c, stroke=o, stroke_width=lw * .8))
    for dr, th in ports.items():
        s.append(rot(R(cx + .08 * c, cy - .12 * c, .16 * c, .24 * c, 'url(#brF)', stroke=o, stroke_width=lw), ANG[dr], cx, cy))
        s.append(port(cx, cy, c, dr, th, fixed=True))
    wx, wy = cx - .02 * c, cy + .13 * c
    s.append(C(wx, wy, .15 * c, 'none', stroke=o, stroke_width=c * .075))
    s.append(C(wx, wy, .15 * c, 'none', stroke=P['red'], stroke_width=c * .045))
    for k in range(3):
        a = math.pi / 3 * k + .3
        s.append(Ln(wx - math.cos(a) * .14 * c, wy - math.sin(a) * .14 * c, wx + math.cos(a) * .14 * c, wy + math.sin(a) * .14 * c, P['red'], c * .032))
    s.append(C(wx, wy, .045 * c, P['brass'], stroke=o, stroke_width=lw * .8))
    return ''.join(s)


def stub(cx, cy, c, pd, th, mount):
    o, lw, s = P['ol'], c * .03, []
    s.append(rot(R(cx, cy - .15 * c, .56 * c, .30 * c, 'url(#irV)', stroke=o, stroke_width=lw), ANG[mount], cx, cy))
    if mount != OPP[pd]:
        s.append(C(cx, cy, .19 * c, 'url(#irV)', stroke=o, stroke_width=lw))
    s.append(rot(R(cx - .02 * c, cy - .15 * c, .26 * c, .30 * c, 'url(#irV)', stroke=o, stroke_width=lw), ANG[pd], cx, cy))
    clamp = (R(cx + .30 * c, cy - .21 * c, .08 * c, .42 * c, '#394046', rx=.015 * c, stroke=o, stroke_width=lw * .8)
             + C(cx + .34 * c, cy - .25 * c, .03 * c, P['steel'], stroke=o, stroke_width=lw * .6)
             + C(cx + .34 * c, cy + .25 * c, .03 * c, P['steel'], stroke=o, stroke_width=lw * .6))
    s.append(rot(clamp, ANG[mount], cx, cy))
    s.append(port(cx, cy, c, pd, th, fixed=True))
    return ''.join(s)


def porcelain(cx, cy, c):
    o, lw, s = P['ol'], c * .03, []
    s.append(R(cx - .41 * c, cy - .30 * c, .82 * c, .76 * c, 'url(#pc)', rx=.10 * c, stroke=o, stroke_width=lw))
    s.append(R(cx - .45 * c, cy - .42 * c, .90 * c, .13 * c, 'url(#pc)', rx=.06 * c, stroke=o, stroke_width=lw))
    s.append(E(cx + .18 * c, cy - .44 * c, .07 * c, .035 * c, 'url(#st)', stroke=o, stroke_width=lw * .8))
    s.append(Ln(cx - .34 * c, cy - .03 * c, cx + .34 * c, cy - .03 * c, P['cobalt'], c * .02))
    s.append(Ln(cx - .34 * c, cy + .19 * c, cx + .34 * c, cy + .19 * c, P['cobalt'], c * .02))
    for i in range(5):
        x = cx - .28 * c + i * .14 * c
        s.append(Pg([(x, cy + .02 * c), (x + .05 * c, cy + .08 * c), (x, cy + .14 * c), (x - .05 * c, cy + .08 * c)], P['cobalt']))
    s.append(E(cx - .22 * c, cy - .16 * c, .09 * c, .05 * c, '#FFFFFF', opacity='.9',
               transform='rotate(-20 %s %s)' % (n(cx - .22 * c), n(cy - .16 * c))))
    return ''.join(s)


def fitting(cx, cy, c, ports):
    o, lw, s = P['ol'], c * .03, []
    ds = list(ports)
    for dr in ds:
        s.append(rot(R(cx - .02 * c, cy - .15 * c, .26 * c, .30 * c, 'url(#br)', stroke=o, stroke_width=lw), ANG[dr], cx, cy))
    if len(ds) == 2 and OPP[ds[0]] == ds[1]:
        hexp = [(cx - .16 * c, cy - .22 * c), (cx + .16 * c, cy - .22 * c), (cx + .2 * c, cy), (cx + .16 * c, cy + .22 * c), (cx - .16 * c, cy + .22 * c), (cx - .2 * c, cy)]
        s.append(rot(Pg(hexp, 'url(#br)', stroke=o, stroke_width=lw, stroke_linejoin='round'), ANG[ds[0]] + 90, cx, cy))
    else:
        s.append(C(cx, cy, .22 * c, 'url(#br)', stroke=o, stroke_width=lw))
        s.append(C(cx - .06 * c, cy - .07 * c, .07 * c, P['hi'], opacity='.7'))
    for dr, th in ports.items():
        s.append(port(cx, cy, c, dr, th))
    return ''.join(s)


def face(cx, cy, c, mood, look=(0, 0)):
    o, lw, s = P['ol'], c * .024, []
    for sx in (-1, 1):
        x = cx + sx * .11 * c
        if mood == 'happy':
            s.append(Pa(dd('M', x - .05 * c, cy + .01 * c, 'q', .05 * c, -.08 * c, .10 * c, 0), stroke=o, stroke_width=lw * 1.4, stroke_linecap='round'))
        else:
            s.append(E(x, cy, .048 * c, .062 * c, '#FFFFFF', stroke=o, stroke_width=lw))
            s.append(C(x + look[0] * .016 * c, cy + .012 * c + look[1] * .016 * c, .024 * c, o))
            s.append(Ln(x + sx * .055 * c, cy - .10 * c, x - sx * .035 * c, cy - .07 * c, o, lw * 1.3))
    if mood == 'happy':
        s.append(Pa(dd('M', cx - .085 * c, cy + .075 * c, 'Q', cx, cy + .19 * c, cx + .085 * c, cy + .075 * c, 'Z'), '#7A2D2A', stroke=o, stroke_width=lw))
    else:
        s.append(Pa(dd('M', cx - .07 * c, cy + .13 * c, 'Q', cx, cy + .075 * c, cx + .07 * c, cy + .13 * c), stroke=o, stroke_width=lw * 1.3, stroke_linecap='round'))
    return ''.join(s)


def bath(cx, cy, c, wet):
    o, lw, s = P['ol'], c * .03, []
    top = cy - .10 * c
    for fx in (-1, 1):
        x = cx + fx * .24 * c
        s.append(Pg([(x - .05 * c, cy + .30 * c), (x + .05 * c, cy + .30 * c), (x + .08 * c, cy + .47 * c), (x - .08 * c, cy + .47 * c)],
                    'url(#brF)', stroke=o, stroke_width=lw, stroke_linejoin='round'))
    s.append(Pa(dd('M', cx - .40 * c, top, 'L', cx + .40 * c, top, 'Q', cx + .38 * c, cy + .36 * c, cx + .15 * c, cy + .36 * c,
                   'L', cx - .15 * c, cy + .36 * c, 'Q', cx - .38 * c, cy + .36 * c, cx - .40 * c, top, 'Z'),
                'url(#pc)', stroke=o, stroke_width=lw, stroke_linejoin='round'))
    if wet:
        s.append(R(cx - .38 * c, top - .11 * c, .76 * c, .12 * c, 'url(#wt)', rx=.04 * c, stroke=o, stroke_width=lw * .8))
        for bx, br in ((-.28, .05), (-.16, .065), (-.02, .05), (.12, .06), (.26, .045)):
            s.append(C(cx + bx * c, top - .14 * c, br * c, P['foam'], stroke=o, stroke_width=c * .016))
    s.append(R(cx - .45 * c, top - .04 * c, .90 * c, .09 * c, 'url(#pc)', rx=.045 * c, stroke=o, stroke_width=lw))
    s.append(face(cx, cy + .11 * c, c, 'happy' if wet else 'grumpy', (-1, 0)))
    return ''.join(s)


def toilet(cx, cy, c, wet):
    o, lw, s = P['ol'], c * .03, []
    s.append(R(cx - .36 * c, cy - .42 * c, .28 * c, .40 * c, 'url(#pc)', rx=.05 * c, stroke=o, stroke_width=lw))
    s.append(R(cx - .39 * c, cy - .47 * c, .34 * c, .08 * c, 'url(#pc)', rx=.03 * c, stroke=o, stroke_width=lw))
    s.append(E(cx - .22 * c, cy - .48 * c, .05 * c, .02 * c, 'url(#st)', stroke=o, stroke_width=lw * .7))
    s.append(Pa(dd('M', cx - .12 * c, cy - .02 * c, 'L', cx + .44 * c, cy - .02 * c, 'Q', cx + .44 * c, cy + .26 * c, cx + .14 * c, cy + .28 * c,
                   'L', cx + .10 * c, cy + .47 * c, 'L', cx - .14 * c, cy + .47 * c, 'L', cx - .12 * c, cy + .20 * c, 'Z'),
                'url(#pc)', stroke=o, stroke_width=lw, stroke_linejoin='round'))
    s.append(R(cx - .14 * c, cy - .08 * c, .60 * c, .07 * c, '#ECE6D8', rx=.035 * c, stroke=o, stroke_width=lw))
    if wet:
        s.append(Pa(dd('M', cx + .02 * c, cy - .13 * c, 'q', .08 * c, -.10 * c, .16 * c, 0, 't', .16 * c, 0), stroke=P['water'], stroke_width=c * .035, stroke_linecap='round'))
    s.append(face(cx + .17 * c, cy + .12 * c, c * .85, 'happy' if wet else 'grumpy', (-1, 0)))
    return ''.join(s)


def sink(cx, cy, c, wet):
    o, lw, s = P['ol'], c * .03, []
    s.append(R(cx - .30 * c, cy + .08 * c, .76 * c, .39 * c, '#E7E1D2', rx=.03 * c, stroke=o, stroke_width=lw))
    s.append(Ln(cx + .08 * c, cy + .12 * c, cx + .08 * c, cy + .43 * c, o, lw * .8))
    s.append(C(cx + .14 * c, cy + .28 * c, .02 * c, P['steel'], stroke=o, stroke_width=lw * .6))
    for px, a in ((-.16, -18), (-.02, 8), (.12, -6)):
        s.append(E(cx + px * c, cy - .10 * c, .12 * c, .045 * c, 'url(#pc)', stroke=o, stroke_width=lw * .8,
                   transform='rotate(%d %s %s)' % (a, n(cx + px * c), n(cy - .10 * c))))
    tap = dd('M', cx + .32 * c, cy - .06 * c, 'L', cx + .32 * c, cy - .34 * c, 'Q', cx + .32 * c, cy - .44 * c, cx + .20 * c, cy - .44 * c,
             'L', cx + .10 * c, cy - .44 * c, 'L', cx + .10 * c, cy - .37 * c)
    s.append(Pa(tap, stroke=o, stroke_width=c * .085, stroke_linecap='round', stroke_linejoin='round'))
    s.append(Pa(tap, stroke=P['steel'], stroke_width=c * .05, stroke_linecap='round', stroke_linejoin='round'))
    if wet:
        s.append(Ln(cx + .10 * c, cy - .34 * c, cx + .10 * c, cy - .04 * c, P['water'], c * .04))
    s.append(Pa(dd('M', cx - .36 * c, cy - .08 * c, 'L', cx + .46 * c, cy - .08 * c, 'L', cx + .40 * c, cy + .10 * c, 'L', cx - .30 * c, cy + .10 * c, 'Z'),
                'url(#st)', stroke=o, stroke_width=lw, stroke_linejoin='round'))
    s.append(face(cx - .12 * c, cy + .27 * c, c * .85, 'happy' if wet else 'grumpy', (-1, 0)))
    return ''.join(s)


def fixture(cx, cy, c, what, pd, th, wet):
    fn = {'bath': bath, 'toilet': toilet, 'sink': sink}.get(what, bath)
    body = fn(cx + (.06 * c if pd in ('left', 'right') else 0), cy, c, wet)
    if pd == 'right':
        body = G(body, transform='translate(%s 0) scale(-1 1)' % n(2 * cx))
    return body + port(cx, cy - .02 * c, c, pd, th, fixed=True)


def drain(cx, cy, c):
    x0, y0 = cx - c / 2, cy - c / 2
    s = [R(x0, y0, c, c, '#172024'), R(x0, y0, c, c * .22, P['water_dk'], opacity='.6')]
    for k in range(3):
        r = c * (.14 + k * .1)
        s.append(Pa(dd('M', cx - r, cy + c * .08, 'A', r, r * .42, 0, 0, 1, cx + r, cy + c * .08), stroke=P['water'],
                    stroke_width=c * .032, opacity='%.2f' % (.85 - k * .22), stroke_linecap='round'))
    s.append(C(cx, cy + c * .08, c * .05, P['water_lt'], opacity='.8'))
    s.append(R(x0 + c * .04, y0 - c * .03, c * .92, c * .07, P['steel'], rx=c * .025, stroke=P['ol'], stroke_width=c * .025))
    return ''.join(s)


def drop(x, y, r):
    return Pa(dd('M', x, y - r * 1.8, 'Q', x + r * 1.1, y - r * .2, x, y + r, 'Q', x - r * 1.1, y - r * .2, x, y - r * 1.8, 'Z'),
              P['water'], stroke=P['ol'], stroke_width=r * .18)


def jet(x, yb, h, c):
    s = [R(x - c * .16, yb - h, c * .32, h, 'url(#wt)', rx=c * .1, stroke=P['ol'], stroke_width=c * .03)]
    for fx, fy, fr in ((-.12, 0, .12), (.1, -.04, .13), (0, -.12, .12)):
        s.append(C(x + fx * c, yb - h + fy * c, fr * c, P['foam'], stroke=P['ol'], stroke_width=c * .02))
    return ''.join(s)


def fluff(x, y, c):
    s = []
    for fx, fy, sx in ((-.02, -.22, 1), (.02, .18, -1), (.05, -.06, 1)):
        s.append(Pa(dd('M', x + fx * c, y + fy * c, 'q', .05 * c, -.06 * c * sx, .10 * c, 0, 't', .08 * c, .03 * c * sx),
                    stroke='#FFFFFF', stroke_width=c * .032, stroke_linecap='round', opacity='.95'))
    return ''.join(s)


# ---------------------------------------------------------------- комната

def room(ox, oy, W, H, c):
    x0, y0, w, h = ox, oy, W * c, H * c
    sp = y0 + h * .34
    s = [R(x0, y0, w, sp - y0, P['wash']), R(x0, sp, w, y0 + h - sp, P['paint']),
         R(x0, sp - c * .035, w, c * .07, P['stripe']), R(x0, sp + c * .07, w, c * .12, '#FFFFFF', opacity='.05')]
    for i in range(int(W * 3)):
        x = x0 + (i + .5) * c / 3
        s.append(Ln(x, sp + c * .3, x + c * .04, y0 + h, '#000000', 1.2, opacity='.04'))
    s.append(R(x0, y0, w, h, 'url(#vg)'))
    return ''.join(s)


def walls(grid, ox, oy, c, tile):
    base, grout, hi = TILE[tile]
    H, W = len(grid), len(grid[0])
    inb = lambda x, y: 1 <= x <= W and 1 <= y <= H
    wl = lambda x, y: inb(x, y) and grid[y - 1][x - 1] == '#'
    s, h2 = [], c / 2
    cells = [(x, y) for y in range(1, H + 1) for x in range(1, W + 1) if wl(x, y)]
    for x, y in cells:
        x0, y0 = ox + (x - 1) * c, oy + (y - 1) * c
        s.append(R(x0, y0, c, c, grout))
        for i in (0, 1):
            for j in (0, 1):
                tx, ty = x0 + i * h2, y0 + j * h2
                s.append(R(tx + c * .02, ty + c * .02, h2 - c * .04, h2 - c * .04, base, rx=c * .035))
                s.append(Ln(tx + c * .07, ty + c * .065, tx + h2 - c * .14, ty + c * .065, hi, c * .02, opacity='.85'))
    for x, y in cells:
        x0, y0 = ox + (x - 1) * c, oy + (y - 1) * c
        if inb(x, y - 1) and not wl(x, y - 1):
            s.append(R(x0, y0, c, c * .08, hi, opacity='.9'))
        if inb(x, y + 1) and not wl(x, y + 1):
            s.append(R(x0, y0 + c * .87, c, c * .13, '#000000', opacity='.22'))
        if inb(x + 1, y) and not wl(x + 1, y):
            s.append(R(x0 + c * .9, y0, c * .1, c, '#000000', opacity='.14'))
        if inb(x - 1, y) and not wl(x - 1, y):
            s.append(R(x0, y0, c * .06, c, '#FFFFFF', opacity='.25'))
    for x, y in cells:
        x0, y0 = ox + (x - 1) * c, oy + (y - 1) * c
        for (nx, ny), (a, b, e, f) in (((x, y - 1), (x0, y0, x0 + c, y0)), ((x, y + 1), (x0, y0 + c, x0 + c, y0 + c)),
                                       ((x - 1, y), (x0, y0, x0, y0 + c)), ((x + 1, y), (x0 + c, y0, x0 + c, y0 + c))):
            if inb(nx, ny) and not wl(nx, ny):
                s.append(Ln(a, b, e, f, P['ol'], c * .05))
    return ''.join(s)


# ---------------------------------------------------------------- Лапидус

def sgn(v):
    return (v > 0) - (v < 0)


def smooth(pts, c):
    r = .5 * c
    parts, dense, cur = ['M %s %s' % (n(pts[0][0]), n(pts[0][1]))], [pts[0]], pts[0]

    def seg(a, b):
        m = max(2, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 3))
        return [(a[0] + (b[0] - a[0]) * k / m, a[1] + (b[1] - a[1]) * k / m) for k in range(1, m + 1)]

    def quad(a, p, b):
        return [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * p[0] + t * t * b[0], (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * p[1] + t * t * b[1])
                for t in (k / 16.0 for k in range(1, 17))]

    for i in range(1, len(pts) - 1):
        p0, p1, p2 = pts[i - 1], pts[i], pts[i + 1]
        di = (sgn(p1[0] - p0[0]), sgn(p1[1] - p0[1]))
        do = (sgn(p2[0] - p1[0]), sgn(p2[1] - p1[1]))
        if di == do:
            continue
        a = (p1[0] - di[0] * r, p1[1] - di[1] * r)
        b = (p1[0] + do[0] * r, p1[1] + do[1] * r)
        parts.append('L %s %s Q %s %s %s %s' % (n(a[0]), n(a[1]), n(p1[0]), n(p1[1]), n(b[0]), n(b[1])))
        dense += seg(cur, a) + quad(a, p1, b)
        cur = b
    parts.append('L %s %s' % (n(pts[-1][0]), n(pts[-1][1])))
    dense += seg(cur, pts[-1])
    return ' '.join(parts), dense


def ribs(dense, step, skip):
    out, acc, nxt = [], 0.0, step * .5
    for i in range(1, len(dense)):
        a, b = dense[i - 1], dense[i]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < 1e-6:
            continue
        while acc + L >= nxt:
            t = (nxt - acc) / L
            px, py = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            if all(math.hypot(px - q[0], py - q[1]) > rr for q, rr in skip):
                out.append((px, py, (b[0] - a[0]) / L, (b[1] - a[1]) / L))
            nxt += step
        acc += L
    return out


def dname(a, b):
    return {(1, 0): 'right', (-1, 0): 'left', (0, 1): 'down', (0, -1): 'up'}[(sgn(a[0] - b[0]), sgn(a[1] - b[1]))]


def heel(pt, dr, c, active, screwed):
    cx, cy = pt
    o, lw, s = P['ol'], c * .03, []
    side = 1 if dr == 'left' else -1
    for i in range(4):
        tx = cx - .01 * c + i * .052 * c
        if active:
            s.append(E(tx, cy + side * .30 * c, .032 * c, .062 * c, P['skin'], stroke=o, stroke_width=c * .02))
        else:
            s.append(E(tx + .01 * c, cy + side * .255 * c, .03 * c, .032 * c, P['skin'], stroke=o, stroke_width=c * .02))
    s.append(R(cx - .03 * c, cy - .23 * c, .15 * c, .46 * c, 'url(#br)', rx=.03 * c, stroke=o, stroke_width=lw))
    s.append(R(cx + .11 * c, cy - .16 * c, .38 * c, .32 * c, 'url(#br)', rx=.05 * c, stroke=o, stroke_width=lw))
    for i in range(5):
        x = cx + .16 * c + i * .06 * c
        s.append(Ln(x, cy - .145 * c, x + .04 * c, cy + .145 * c, P['sh'], c * .02))
    if screwed:
        s.append(fluff(cx + .50 * c, cy, c))
    return rot(''.join(s), ANG[dr], cx, cy)


def head(pt, dr, c, active, screwed):
    cx, cy = pt
    o, lw, s = P['ol'], c * .032, []
    dx, dy = DV[dr]
    fc = ([(-.34, .06, .12), (-.40, -.10, .10), (-.30, .22, .10), (-.22, -.22, .09)] if dr == 'up'
          else [(-.34, -.18, .09), (-.24, -.30, .11), (-.08, -.38, .13), (.10, -.36, .12), (.25, -.28, .10)])
    for fx, fy, fr in fc:
        s.append(C(cx + fx * c, cy + fy * c, fr * c, P['foam'], stroke=o, stroke_width=c * .02))
        s.append(C(cx + fx * c + fr * c * .25, cy + fy * c + fr * c * .3, fr * c * .5, P['foam_sh'], opacity='.55'))
    Rr, oxo = .36 * c, .03 * c
    hexp = [(cx + oxo + Rr * math.cos(math.radians(a)), cy + Rr * math.sin(math.radians(a))) for a in range(0, 360, 60)]
    mx = cx + oxo + Rr * .80
    nut = [Pg(hexp, 'url(#br)', stroke=o, stroke_width=lw, stroke_linejoin='round'),
           Ln(cx + oxo - Rr * .5, cy - Rr * .84, cx + oxo - Rr * .5, cy + Rr * .84, P['sh'], c * .016),
           Ln(cx + oxo + Rr * .5, cy - Rr * .84, cx + oxo + Rr * .5, cy + Rr * .84, P['hi'], c * .016),
           E(mx, cy + .01 * c, .075 * c, .155 * c, '#1B140F', stroke=o, stroke_width=c * .02),
           Pa(dd('M', mx - .03 * c, cy - .09 * c, 'Q', mx + .02 * c, cy, mx - .03 * c, cy + .09 * c), stroke='#8A7550', stroke_width=c * .014),
           Pa(dd('M', mx + .01 * c, cy - .11 * c, 'Q', mx + .06 * c, cy, mx + .01 * c, cy + .11 * c), stroke='#8A7550', stroke_width=c * .014)]
    if screwed:
        nut.append(fluff(cx + .52 * c, cy, c))
    s.append(rot(''.join(nut), ANG[dr], cx, cy))
    if dr in ('left', 'right'):
        eyes = [(cx + dx * .02 * c - .10 * c, cy - .10 * c), (cx + dx * .02 * c + .10 * c, cy - .10 * c)]
    elif dr == 'up':
        eyes = [(cx - .10 * c, cy + .08 * c), (cx + .10 * c, cy + .08 * c)]
    else:
        eyes = [(cx - .10 * c, cy - .12 * c), (cx + .10 * c, cy - .12 * c)]
    for x, y in eyes:
        if active:
            s.append(E(x, y, .058 * c, .075 * c, '#FFFFFF', stroke=o, stroke_width=c * .022))
            s.append(C(x + dx * .022 * c, y + dy * .022 * c + .008 * c, .03 * c, o))
            s.append(C(x + dx * .022 * c - .01 * c, y + dy * .022 * c - .005 * c, .009 * c, '#FFFFFF'))
        else:
            s.append(Pa(dd('M', x - .05 * c, y, 'Q', x, y + .045 * c, x + .05 * c, y), stroke=o, stroke_width=c * .026, stroke_linecap='round'))
    return ''.join(s)


def lapidus(pts, c, Lmin=2, Lmax=4, active='head', wet=False, screwed=(False, False), ring=True):
    o, w, t = P['ol'], .44 * c, .035 * c
    dstr, dense = smooth(pts, c)
    s = []
    if ring:
        ax, ay = pts[-1] if active == 'head' else pts[0]
        s.append(C(ax, ay, .56 * c, P['water'], opacity='.16'))
        s.append(C(ax, ay, .56 * c, 'none', stroke=P['water'], stroke_width=c * .04, opacity='.75',
                   stroke_dasharray='%s %s' % (n(c * .14), n(c * .09))))
    base = dict(stroke_linecap='round', stroke_linejoin='round')
    s.append(Pa(dstr, stroke=o, stroke_width=w + 2 * t, **base))
    s.append(Pa(dstr, stroke=P['hose_sh'], stroke_width=w, **base))
    s.append(G(Pa(dstr, stroke=P['hose'], stroke_width=w * .74, **base), transform='translate(%s %s)' % (n(-.03 * c), n(-.05 * c))))
    per = 4 + 4.0 * (Lmax - len(pts)) / max(1, Lmax - Lmin)
    for px, py, tx, ty in ribs(dense, c / per, [(pts[-1], .40 * c), (pts[0], .34 * c)]):
        hw = w * .47
        s.append(Ln(px + ty * hw, py - tx * hw, px - ty * hw, py + tx * hw, P['rib'], c * .022))
    if wet:
        s.append(Pa(dstr, stroke=P['water'], stroke_width=c * .11, stroke_dasharray='%s %s' % (n(c * .22), n(c * .1)), **base))
        s.append(Pa(dstr, stroke=P['water_lt'], stroke_width=c * .03, stroke_dasharray='%s %s' % (n(c * .12), n(c * .2)), **base))
    s.append(heel(pts[0], dname(pts[0], pts[1]), c, active == 'heel', screwed[0]))
    s.append(head(pts[-1], dname(pts[-1], pts[-2]), c, active == 'head', screwed[1]))
    return ''.join(s)


# ---------------------------------------------------------------- уровень и HUD

def cellc(ox, oy, c, x, y):
    return ox + (x - .5) * c, oy + (y - .5) * c


def level_layers(lv, ox, oy, c, active='head', wet=False, no_lap=False):
    grid = lv['grid']
    H, W = len(grid), len(grid[0])
    wl = lambda x, y: 1 <= x <= W and 1 <= y <= H and grid[y - 1][x - 1] == '#'
    s = [room(ox, oy, W, H, c), walls(grid, ox, oy, c, lv.get('tile', 'mint'))]
    for y in range(1, H + 1):
        for x in range(1, W + 1):
            if grid[y - 1][x - 1] == '~':
                s.append(drain(*cellc(ox, oy, c, x, y), c=c))
    lap = None
    for ob in lv['objects']:
        k = ob['kind']
        if k == 'lapidus':
            lap = ob
            continue
        x, y = ob['at']
        cx, cy = cellc(ox, oy, c, x, y)
        ports = ob.get('ports', {})
        if k == 'source':
            s.append(source(cx, cy, c, ports, wl(x, y - 1), wl(x, y + 1)))
        elif k == 'fixture':
            pd, th = list(ports.items())[0]
            s.append(fixture(cx, cy, c, ob.get('what', 'bath'), pd, th, wet))
        elif k == 'stub':
            pd, th = list(ports.items())[0]
            cand = [OPP[pd]] + [m for m in ('left', 'right', 'up', 'down') if m not in (pd, OPP[pd])]
            mount = next((m for m in cand if wl(x + DV[m][0], y + DV[m][1])), OPP[pd])
            s.append(stub(cx, cy, c, pd, th, mount))
        elif k == 'porcelain':
            s.append(porcelain(cx, cy, c))
        elif k == 'fitting':
            s.append(fitting(cx, cy, c, ports))
    if lap and not no_lap:
        pts = [cellc(ox, oy, c, x, y) for x, y in lap['cells']]
        Lr = lv.get('length', [2, 4])
        s.append(lapidus(pts, c, Lr[0], Lr[1], active, wet))
    return ''.join(s)


def geom(lv):
    H, W = len(lv['grid']), len(lv['grid'][0])
    c = min(120, 1920 // W, 1080 // H)
    return c, (1920 - W * c) // 2, (1080 - H * c) // 2


def icon(kind, x, y, r=50):
    s, wc = [C(x, y, r, 'rgba(26,21,16,0.86)', stroke=P['brass'], stroke_width=4)], P['cream']
    if kind == 'undo':
        s.append(Pa(dd('M', x + 15, y + 17, 'A', 21, 21, 0, 1, 0, x - 20, y + 1), stroke=wc, stroke_width=7, stroke_linecap='round'))
        s.append(Pg([(x - 31, y - 3), (x - 9, y - 3), (x - 20, y + 15)], wc))
    elif kind == 'restart':
        s.append(Pa(dd('M', x + 20, y + 2, 'A', 20, 20, 0, 1, 1, x + 7, y - 19), stroke=wc, stroke_width=7, stroke_linecap='round'))
        s.append(Pg([(x + 1, y - 30), (x + 19, y - 19), (x + 1, y - 8)], wc))
    elif kind == 'hint':
        s.append(T(x, y + 21, '?', 62, wc, weight='bold', anchor='middle'))
    elif kind == 'menu':
        for k in (-15, 0, 15):
            s.append(Ln(x - 21, y + k, x + 21, y + k, wc, 7))
    return ''.join(s)


def plate(x, y, w, h):
    return R(x, y, w, h, 'rgba(24,20,16,0.82)', rx=18, stroke=P['brass'], stroke_width=3)


def hud(lv, ox, moves=0, active='head'):
    s = []
    pw = max(200, ox - 48)
    s.append(plate(24, 24, pw, 146))
    s.append(T(48, 82, 'КВ. %d' % lv['flat'], 48, P['hi'], weight='bold'))
    s.append(T(48, 138, lv['name'], 40 if len(lv['name']) < 12 else 34, P['cream'], weight='bold'))
    s.append(plate(24, 186, pw, 86))
    s.append(T(48, 243, 'Ходы: %d' % moves, 42, P['cream']))
    s.append(plate(24, 288, pw, 86))
    s.append(T(48, 345, 'Ходит: ' + ('голова' if active == 'head' else 'ноги'), 38, P['cream']))
    bx = 1920 - max(80, ox / 2)
    for i, k in enumerate(('undo', 'restart', 'hint', 'menu')):
        s.append(icon(k, bx, 150 + i * 140))
    return ''.join(s)


def level_screen(lv, moves=0, active='head', overlay='', **kw):
    c, ox, oy = geom(lv)
    return R(0, 0, 1920, 1080, 'url(#stair)') + level_layers(lv, ox, oy, c, active=active, **kw) + hud(lv, ox, moves, active) + overlay


def toast(msg):
    w = 60 + len(msg) * 17
    return R(960 - w / 2, 968, w, 74, 'rgba(22,18,14,0.9)', rx=37, stroke=P['brass'], stroke_width=3) + T(960, 1017, msg, 38, P['cream'], anchor='middle')


def mark(x, y, ok, k=1.0):
    if ok:
        return Pa(dd('M', x - 18 * k, y, 'L', x - 5 * k, y + 14 * k, 'L', x + 20 * k, y - 16 * k), stroke=P['ok'], stroke_width=9 * k,
                  stroke_linecap='round', stroke_linejoin='round')
    return Ln(x - 15 * k, y - 15 * k, x + 15 * k, y + 15 * k, P['bad'], 9 * k) + Ln(x + 15 * k, y - 15 * k, x - 15 * k, y + 15 * k, P['bad'], 9 * k)


def arrow(x1, y1, x2, y2, col=None, w=6):
    col = col or P['ink']
    a = math.atan2(y2 - y1, x2 - x1)
    return (Ln(x1, y1, x2 - math.cos(a) * 8, y2 - math.sin(a) * 8, col, w)
            + Pg([(x2, y2), (x2 - 18 * math.cos(a - .45), y2 - 18 * math.sin(a - .45)), (x2 - 18 * math.cos(a + .45), y2 - 18 * math.sin(a + .45))], col))


# ---------------------------------------------------------------- экраны

LOGO = {'Л': ['M 8 140 L 22 26 Q 26 0 50 0 L 90 0 L 90 140'], 'А': ['M 2 140 L 46 0 L 90 140', 'M 22 88 L 70 88'],
        'П': ['M 8 140 L 8 0 L 84 0 L 84 140'], 'И': ['M 8 0 L 8 140 L 84 0 L 84 140'],
        'Д': ['M 0 158 L 0 118 L 96 118 L 96 158', 'M 16 118 L 30 0 L 82 0 L 82 118'],
        'У': ['M 4 0 L 48 80', 'M 90 0 L 30 140'],
        'С': ['M 88 24 Q 72 0 46 0 Q 4 0 4 70 Q 4 140 46 140 Q 72 140 88 116']}


def logo(x, y, sc=1.0, word='ЛАПИДУС'):
    items, cx = [], 0
    for ch in word:
        for p in LOGO[ch]:
            items.append((cx, p))
        cx += 118 if ch == 'Д' else 112

    def lay(stroke, w, extra=''):
        return ''.join('<path d="%s" transform="translate(%d 0)" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s/>'
                       % (p, dx, stroke, n(w), extra) for dx, p in items)
    nuts = []
    for dx, p in items:
        v = [float(t) for t in p.replace('M', ' ').replace('L', ' ').replace('Q', ' ').split()]
        for ax, ay in ((v[0], v[1]), (v[-2], v[-1])):
            nuts.append(Pg([(dx + ax + 17 * math.cos(math.radians(a)), ay + 17 * math.sin(math.radians(a))) for a in range(0, 360, 60)],
                           'url(#brL)', stroke=P['ol'], stroke_width=4))
    body = (lay(P['ol'], 36) + lay('url(#brL)', 25) + '<g transform="translate(-2 -3)">' + lay(P['hi'], 7, ' opacity="0.8"') + '</g>'
            + lay(P['water'], 8, ' stroke-dasharray="22 14"') + ''.join(nuts))
    return '<g transform="translate(%s %s) scale(%s)">%s</g>' % (n(x), n(y), n(sc), body)


def menu_screen():
    o, s = P['ol'], [R(0, 0, 1920, 1080, 'url(#bsm)')]
    for row in range(12):
        for col in range(15):
            s.append(R(col * 150 + (75 if row % 2 else 0) - 60, 290 + row * 70, 144, 64, 'none', stroke='#000000', stroke_width=2, opacity='.2'))
    s.append(Pg([(960, 70), (520, 1080), (1400, 1080)], 'url(#bulb)'))
    s.append(R(-10, 150, 1940, 46, 'url(#irV)', stroke=o, stroke_width=4))
    s.append(R(-10, 228, 1940, 30, 'url(#irV)', stroke=o, stroke_width=4))
    for xk in (300, 760, 1240, 1680):
        s.append(R(xk, 144, 26, 58, '#3A3F45', rx=6, stroke=o, stroke_width=3))
    s.append(Ln(960, 0, 960, 70, '#1A1A1A', 4))
    s.append(C(960, 92, 26, '#FFF3C4', stroke=o, stroke_width=4))
    s.append(R(340, 258, 80, 830, 'url(#ir)', stroke=o, stroke_width=5))
    for yk in (330, 920):
        s.append(R(326, yk, 108, 34, 'url(#ir)', rx=8, stroke=o, stroke_width=4))
    wx, wy, wr = 380, 660, 150
    s.append(C(wx, wy, wr, 'none', stroke=o, stroke_width=46))
    s.append(C(wx, wy, wr, 'none', stroke=P['red'], stroke_width=34))
    for k in range(6):
        a = math.pi / 3 * k + .26
        s.append(Ln(wx, wy, wx + math.cos(a) * wr, wy + math.sin(a) * wr, o, 30))
        s.append(Ln(wx, wy, wx + math.cos(a) * wr, wy + math.sin(a) * wr, P['red'], 18))
    s.append(C(wx, wy, 40, 'url(#br)', stroke=o, stroke_width=5))
    s.append(Ln(520, 540, 600, 640, '#8A8A8A', 3))
    s.append(G(R(560, 630, 250, 100, '#E9DFB8', rx=8, stroke=o, stroke_width=3) + T(685, 672, 'ГЛАВНЫЙ', 32, P['ink'], weight='bold', anchor='middle')
               + T(685, 712, 'ВЕНТИЛЬ ДОМА', 32, P['ink'], weight='bold', anchor='middle'), transform='rotate(6 685 680)'))
    s.append(logo(522, 300, 1.12))
    s.append(T(960, 548, 'НИ КАПЛИ', 74, P['cream'], weight='bold', anchor='middle', letter_spacing='14', stroke=o, stroke_width=3, paint_order='stroke'))
    for i, it in enumerate(['Продолжить', 'Квартиры', 'Паспорт изделия', 'Настройки', 'Выход']):
        by, sel = 620 + i * 88, i == 0
        s.append(R(1180, by, 520, 72, 'url(#br)' if sel else 'rgba(201,154,46,0.16)', rx=12, stroke=P['brass'], stroke_width=4))
        for bx in (1198, 1682):
            s.append(C(bx, by + 36, 7, P['steel'], stroke=o, stroke_width=2))
        s.append(T(1440, by + 50, it, 44, o if sel else P['cream'], weight='bold', anchor='middle'))
    return ''.join(s)


def select_screen():
    o, s = P['ol'], [R(0, 0, 1920, 1080, 'url(#sky)')]
    for i in range(46):
        s.append(C((i * 397) % 1920, (i * 131) % 300 + 20, 1.8, '#FFFFFF', opacity='.5'))
    s.append(R(0, 940, 1920, 140, '#2B2A28'))
    bx0, bx1, top, rx = 560, 1360, 190, 950
    s.append(R(bx0 - 20, top - 30, bx1 - bx0 + 40, 40, '#6E7478', stroke=o, stroke_width=4))
    s.append(R(bx0, top, bx1 - bx0, 940 - top, '#A7ADB0', stroke=o, stroke_width=5))
    for k in range(1, 5):
        s.append(Ln(bx0, top + k * 150, bx1, top + k * 150, '#7E8589', 3))
    s.append(R(bx0, 940, bx1 - bx0, 120, '#3B3632', stroke=o, stroke_width=4))
    s.append(T(bx0 + 30, 1012, 'подвал · главный вентиль', 30, '#C9C0AE'))
    s.append(R(rx, top - 10, 20, 1060 - top, 'url(#ir)', stroke=o, stroke_width=3))
    s.append(R(rx + 4, 790, 12, 270, P['water']))
    solved, opened = {1}, {2, 3}
    fx = {1: ('bath', 'mint'), 2: ('toilet', 'blue'), 3: ('sink', 'mustard')}
    for apt in range(1, 11):
        fl, left = (apt + 1) // 2, apt % 2 == 1
        y0 = 940 - fl * 150 + 10
        x0 = bx0 + 20 if left else rx + 40
        w, h = 350, 130
        if apt in solved:
            s.append(R(x0, y0, w, h, 'url(#warm)', stroke=o, stroke_width=4))
        elif apt in opened:
            s.append(R(x0, y0, w, h, '#33414F', stroke=P['brass'], stroke_width=6))
        else:
            s.append(R(x0, y0, w, h, '#1B2026', stroke=o, stroke_width=4))
        if apt in fx:
            what, tl = fx[apt]
            s.append(R(x0 + 4, y0 + 86, w - 8, 40, TILE[tl][0], opacity='.9' if apt in solved else '.35'))
            f = {'bath': bath, 'toilet': toilet, 'sink': sink}[what]
            s.append(f(x0 + w - 80, y0 + 66, 96, apt in solved))
            if apt in solved:
                s.append(R(x0 + 96, y0 + 18, 150, 44, 'rgba(255,255,255,0.75)', rx=10, stroke=o, stroke_width=2))
                s.append(T(x0 + 171, y0 + 50, 'акт · 4-й разр.', 26, P['ink'], weight='bold', anchor='middle'))
        else:
            for k in (-1, 1):
                s.append(R(x0 + 30, y0 + 50 + k * 22, w - 60, 22, '#6B4A2E', rx=4, stroke=o, stroke_width=2,
                           transform='rotate(%d %s %s)' % (k * 4, n(x0 + w / 2), n(y0 + 61 + k * 22))))
        s.append(R(x0 + 12, y0 + 12, 64, 46, '#1E4C8C', rx=6, stroke=o, stroke_width=2))
        s.append(T(x0 + 44, y0 + 46, str(apt), 32, '#FFFFFF', weight='bold', anchor='middle'))
    s.append(T(60, 110, 'ПОДЪЕЗД 1', 64, P['cream'], weight='bold', letter_spacing='4'))
    s.append(T(60, 162, 'выберите квартиру', 36, '#C9D3DC'))
    for i, (sw, txt) in enumerate((('url(#warm)', 'горит — акт подписан'), ('#33414F', 'рамка — можно брать'), ('#1B2026', 'доски — в следующей версии'))):
        y = 420 + i * 90
        s.append(R(1430, y, 70, 50, sw, stroke=P['brass'] if i == 1 else o, stroke_width=4))
        s.append(T(1520, y + 37, txt, 34, P['cream']))
    s.append(T(1430, 720, 'открыты две нерешённые', 30, '#C9D3DC'))
    s.append(T(1430, 758, 'квартиры сразу', 30, '#C9D3DC'))
    return ''.join(s)


def request_screen(lv):
    s = [level_screen(lv), R(0, 0, 1920, 1080, '#000000', opacity='.55')]
    note = [R(610, 300, 700, 430, '#FBFAF4', rx=6, filter='url(#sh)')]
    for i in range(1, 13):
        note.append(Ln(610, 300 + i * 34, 1310, 300 + i * 34, '#C4D6EC', 1.5))
    for i in range(1, 21):
        note.append(Ln(610 + i * 34, 300, 610 + i * 34, 730, '#C4D6EC', 1.5))
    note.append(Ln(690, 300, 690, 730, '#E28A8A', 2.5))
    for i, ln in enumerate(wrap(lv['texts']['request'], 22)):
        note.append(T(720, 420 + i * 82, ln, 64, '#1D3A8F', font=HAND))
    note.append(T(1270, 700, '— жилец кв. %d' % lv['flat'], 40, '#1D3A8F', font=HAND, anchor='end'))
    note.append(R(890, 282, 140, 46, '#E9DFB8', opacity='.9', transform='rotate(-4 960 305)'))
    s.append(G(''.join(note), transform='rotate(-2 960 515)'))
    s.append(T(960, 250, 'ЗАЯВКА', 46, P['cream'], weight='bold', anchor='middle', letter_spacing='6'))
    s.append(T(960, 820, 'любая клавиша — к работе', 32, P['hi'], anchor='middle'))
    return ''.join(s)


def hint_screen(lv):
    s = [level_screen(lv, moves=7), R(0, 0, 1920, 1080, '#000000', opacity='.35')]
    x0, y0, w, h = 330, 690, 1260, 360
    s.append(R(x0, y0, w, h, 'rgba(20,17,13,0.95)', rx=26, stroke=P['brass'], stroke_width=4, filter='url(#sh)'))
    hx, hy = x0 + 80, y0 + 92
    s.append(Pa(dd('M', hx - 22, hy - 32, 'Q', hx - 46, hy, hx - 22, hy + 32), stroke=P['brass'], stroke_width=18, stroke_linecap='round'))
    s.append(R(hx - 36, hy - 52, 34, 24, P['brass'], rx=8, stroke=P['ol'], stroke_width=2, transform='rotate(-28 %s %s)' % (n(hx - 19), n(hy - 40))))
    s.append(R(hx - 36, hy + 28, 34, 24, P['brass'], rx=8, stroke=P['ol'], stroke_width=2, transform='rotate(28 %s %s)' % (n(hx - 19), n(hy + 40))))
    s.append(T(x0 + 150, y0 + 70, 'Горячая линия управляющей компании', 36, P['hi'], weight='bold'))
    s.append(T(x0 + w - 30, y0 + 50, 'ожидание: до окончания работ', 26, '#9FB0B8', anchor='end'))
    for i, ln in enumerate(wrap(lv['texts']['hints'][0], 58)):
        s.append(T(x0 + 150, y0 + 130 + i * 50, ln, 40, P['cream']))
    for i, lab in enumerate(('1 · Суть', '2 · Я в тупике?', '3 · Вызвать мастера')):
        bx, by = x0 + 150 + i * 354, y0 + 268
        s.append(R(bx, by, 330, 64, P['brass'] if i == 0 else 'rgba(201,154,46,0.18)', rx=32, stroke=P['brass'], stroke_width=3))
        s.append(T(bx + 165, by + 44, lab, 34, P['ol'] if i == 0 else P['cream'], weight='bold', anchor='middle'))
    return ''.join(s)


def washed_screen(lv):
    c, ox, oy = geom(lv)
    s = [R(0, 0, 1920, 1080, 'url(#stair)'), level_layers(lv, ox, oy, c, no_lap=True), hud(lv, ox, 9)]
    for y, row in enumerate(lv['grid']):
        for x, ch in enumerate(row):
            if ch == '~':
                dx, dy = cellc(ox, oy, c, x + 1, y + 1)
                for k in range(4):
                    r = c * (.3 + k * .25)
                    s.append(Pa(dd('M', dx - r, dy - c * .1, 'A', r, r * .38, 0, 0, 1, dx + r, dy - c * .1), stroke=P['water'], stroke_width=c * .05,
                                opacity='%.2f' % (.9 - k * .2), stroke_linecap='round'))
    s.append(R(0, 420, 1920, 210, 'rgba(10,12,14,0.82)'))
    s.append(T(960, 510, 'Лапидус ушёл в канализацию.', 68, P['cream'], weight='bold', anchor='middle'))
    s.append(T(960, 585, 'Не навсегда. Отмена — Z.', 48, P['hi'], anchor='middle'))
    return ''.join(s)


def act_screen(lv):
    s = [level_screen(lv), R(0, 0, 1920, 1080, '#000000', opacity='.62')]
    a = [R(560, 50, 800, 980, P['paper'], rx=6, filter='url(#sh)'),
         T(960, 140, 'АКТ № %d' % lv['flat'], 66, P['ink'], weight='bold', anchor='middle', letter_spacing='3'),
         T(960, 190, 'выполненных работ', 40, P['ink'], anchor='middle'), Ln(620, 222, 1300, 222, P['ink'], 2.5)]
    rows = [('Адрес', 'подъезд 1, квартира %d' % lv['flat']), ('Работы', 'вода к прибору «ванна»'),
            ('Исполнитель', 'гофра самоходная «Лапидус»'), ('Ходов', '21 при норме 18'),
            ('Горячая линия', 'не вызывалась'), ('Мастер', 'не вызывался')]
    y = 290
    for k, v in rows:
        a.append(T(620, y, k + ':', 34, P['ink'], weight='bold'))
        a.append(T(840, y, v, 40, '#1C3C9A', font=HAND))
        a.append(Ln(836, y + 12, 1300, y + 12, '#9AA4B8', 1.5))
        y += 66
    a.append(R(620, 700, 330, 150, 'none', rx=10, stroke=P['ink'], stroke_width=3))
    a.append(T(785, 745, 'РАЗРЯД', 30, P['ink'], weight='bold', anchor='middle', letter_spacing='4'))
    a.append(T(785, 830, '4-й', 84, P['red'], font=HAND, anchor='middle'))
    a.append(T(620, 930, 'Исполнитель ____________', 30, P['ink']))
    a.append(T(790, 922, 'Лапидус', 46, '#1C3C9A', font=HAND, transform='rotate(-6 840 915)'))
    a.append(T(620, 985, 'Жилец ________________', 30, P['ink']))
    sx, sy, r = 1150, 845, 118
    st = (C(sx, sy, r, 'none', stroke=P['stamp'], stroke_width=8) + C(sx, sy, r - 30, 'none', stroke=P['stamp'], stroke_width=3)
          + '<text font-family="%s" font-size="25" font-weight="bold" fill="%s" letter-spacing="2"><textPath href="#ring" xlink:href="#ring">ЖЭУ № 3 · АВАРИЙНО-ДИСПЕТЧЕРСКАЯ СЛУЖБА ·</textPath></text>' % (UI, P['stamp'])
          + T(sx, sy + 12, 'ВЫПОЛНЕНО', 34, P['stamp'], weight='bold', anchor='middle'))
    a.append(G(st, transform='rotate(-14 %d %d)' % (sx, sy), opacity='.86'))
    s.append(G(''.join(a), transform='rotate(-1.2 960 540)'))
    for i, lab in enumerate(('Дальше ›', 'Ещё раз')):
        by = 820 + i * 110
        s.append(R(1440, by, 380, 84, 'url(#br)' if i == 0 else 'rgba(201,154,46,0.2)', rx=42, stroke=P['brass'], stroke_width=4))
        s.append(T(1630, by + 56, lab, 42, P['ol'] if i == 0 else P['cream'], weight='bold', anchor='middle'))
    extra = '<path id="ring" d="M %d %d m -104 0 a 104 104 0 1 1 208 0 a 104 104 0 1 1 -208 0"/>' % (sx, sy)
    return ''.join(s), extra


def pan_moves(px, py):
    c, s = 56, []
    for yy, m, lab in ((py + 150, 4, '+1  растянуться'), (py + 280, 2, '−1  сжаться')):
        s.append(lapidus([(px + 60 + i * c, yy) for i in range(3)], c, 2, 5, ring=False))
        s.append(arrow(px + 232, yy, px + 292, yy))
        s.append(lapidus([(px + 330 + i * c, yy) for i in range(m)], c, 2, 5, ring=False))
        s.append(T(px + 330, yy - 40, lab, 26, P['ink'], weight='bold'))
    return ''.join(s)


def pan_thread(px, py):
    c, s = 64, []
    for i, (a, b, ok) in enumerate((('N', 'V', True), ('N', 'N', False), ('V', 'V', False))):
        y, x = py + 125 + i * 80, px + 230
        s.append(R(x - .45 * c, y - .2 * c, .5 * c, .4 * c, 'url(#irV)', stroke=P['ol'], stroke_width=2))
        s.append(R(x + 1.15 * c - .05 * c, y - .2 * c, .5 * c, .4 * c, 'url(#irV)', stroke=P['ol'], stroke_width=2))
        s.append(port(x, y, c, 'right', a) + port(x + 1.15 * c, y, c, 'left', b))
        s.append(T(px + 40, y + 12, {'N': 'Н', 'V': 'В'}[a] + ' + ' + {'N': 'Н', 'V': 'В'}[b], 34, P['ink'], weight='bold'))
        s.append(mark(px + 470, y, ok))
    return ''.join(s)


def pan_support(px, py):
    c, s = 58, []
    s.append(R(px + 30, py + 250, 70, 70, TILE['mint'][0], stroke=P['ol'], stroke_width=3))
    s.append(R(px + 230, py + 250, 70, 70, TILE['mint'][0], stroke=P['ol'], stroke_width=3))
    s.append(lapidus([(px + 108, py + 170), (px + 166, py + 170), (px + 224, py + 170)], c, 2, 5, ring=False))
    s.append(arrow(px + 166, py + 205, px + 166, py + 300, P['bad']))
    s.append(mark(px + 60, py + 110, False, .8))
    s.append(R(px + 330, py + 70, 150, 26, TILE['mint'][0], stroke=P['ol'], stroke_width=3))
    s.append(stub(px + 405, py + 125, c, 'down', 'N', 'up'))
    s.append(lapidus([(px + 405, py + 299), (px + 405, py + 241), (px + 405, py + 183)], c, 2, 5, ring=False, screwed=(False, True)))
    s.append(mark(px + 490, py + 200, True, .8))
    return ''.join(s)


def pan_drain(px, py):
    c, s = 70, []
    s.append(R(px + 90, py + 255, 150, 60, TILE['mint'][0], stroke=P['ol'], stroke_width=3))
    s.append(R(px + 310, py + 255, 150, 60, TILE['mint'][0], stroke=P['ol'], stroke_width=3))
    s.append(drain(px + 275, py + 290, 70))
    s.append(lapidus([(px + 275, py + 120), (px + 275, py + 185)], c, 2, 5, ring=False))
    s.append(arrow(px + 330, py + 130, px + 330, py + 225, P['bad']))
    s.append(T(px + 360, py + 190, '«смыло»', 40, P['ink'], font=HAND))
    s.append(mark(px + 120, py + 150, False, .9))
    return ''.join(s)


def pan_soap(px, py):
    c, s = 64, []
    y1, y2 = py + 145, py + 275
    s.append(lapidus([(px + 250, y1), (px + 186, y1), (px + 122, y1)], c, 2, 5, active='heel', ring=False))
    s.append(porcelain(px + 316, y1, c) + arrow(px + 360, y1, px + 420, y1) + mark(px + 470, y1, True, .8))
    s.append(lapidus([(px + 122, y2), (px + 186, y2), (px + 250, y2)], c, 2, 5, ring=False))
    s.append(porcelain(px + 316, y2, c) + mark(px + 470, y2, False, .8))
    for bx, by, br in ((285, -30, 9), (296, -12, 6), (278, 8, 7)):
        s.append(C(px + bx, y2 + by, br, '#FFFFFF', stroke=P['ol'], stroke_width=2))
    s.append(T(px + 40, y1 + 8, 'ноги', 28, P['ink'], weight='bold'))
    s.append(T(px + 40, y2 + 8, 'голова', 28, P['ink'], weight='bold'))
    return ''.join(s)


def pan_goal(px, py):
    c, s, y = 64, [], py + 210
    s.append(source(px + 70, y, c, {'right': 'V'}, False, False))
    s.append(lapidus([(px + 134, y), (px + 198, y), (px + 262, y), (px + 326, y)], c, 2, 5, wet=True, screwed=(True, True), ring=False))
    s.append(fixture(px + 390, y, c, 'bath', 'left', 'N', True))
    s.append(mark(px + 480, py + 120, True))
    s.append(T(px + 40, py + 320, 'стояк → Лапидус → прибор, ни капли мимо', 26, P['ink']))
    return ''.join(s)


def passport_screen():
    s = [R(0, 0, 1920, 1080, '#2A3035'), R(70, 40, 1780, 1000, '#F1ECDF', rx=10, filter='url(#sh)')]
    s.append(T(130, 128, 'ПАСПОРТ ИЗДЕЛИЯ', 62, P['ink'], weight='bold', letter_spacing='4'))
    s.append(T(130, 182, 'Гофра самоходная «Лапидус». Длина 2–5 клеток. Совместимость с фаянсом: ногами.', 34, P['ink']))
    s.append(T(130, 224, 'Гарантия на героя не распространяется.', 34, P['ink']))
    panels = (('Ход концом: тянется и сжимается', pan_moves), ('Н входит в В — лицом к лицу', pan_thread),
              ('Без опоры падает, резьба держит', pan_support), ('Слив смывает', pan_drain),
              ('Фаянс толкают только ноги', pan_soap), ('Цель: вода до прибора', pan_goal))
    for i, (title, fn) in enumerate(panels):
        px, py = 130 + (i % 3) * 570, 262 + (i // 3) * 386
        s.append(R(px, py, 540, 356, '#FBF8F0', rx=10, stroke=P['ink'], stroke_width=2.5))
        s.append(C(px + 38, py + 40, 24, P['ink']))
        s.append(T(px + 38, py + 51, str(i + 1), 30, '#FBF8F0', weight='bold', anchor='middle'))
        s.append(T(px + 76, py + 52, title, 32, P['ink'], weight='bold'))
        s.append(fn(px, py))
    return ''.join(s)


def duck(x, y, k=1.0):
    o = P['ol']
    return (E(x, y, 46 * k, 30 * k, '#F4C542', stroke=o, stroke_width=4) + C(x + 30 * k, y - 34 * k, 22 * k, '#F4C542', stroke=o, stroke_width=4)
            + Pa(dd('M', x + 16 * k, y - 50 * k, 'q', 14 * k, -8 * k, 28 * k, 0), stroke='#2E7D4F', stroke_width=7 * k, stroke_linecap='round')
            + Pg([(x + 48 * k, y - 38 * k), (x + 74 * k, y - 32 * k), (x + 48 * k, y - 25 * k)], '#E8742A', stroke=o, stroke_width=3)
            + C(x + 36 * k, y - 40 * k, 4 * k, o))


def tiles_bg(x0, y0, w, h, tl):
    base, grout, hi = TILE[tl]
    s = [R(x0, y0, w, h, grout)]
    for j in range(int(h // 60) + 1):
        for i in range(int(w // 60) + 1):
            s.append(R(x0 + i * 60 + 2, y0 + j * 60 + 2, 56, 56, base, rx=4))
    return ''.join(s)


def scenes_screen():
    s = [R(0, 0, 1920, 1080, '#171B1E'), T(960, 92, 'Немые сцены после победы · ключевые кадры', 48, P['cream'], weight='bold', anchor='middle')]
    clips = ''
    titles = ('Кв. 1 · ванна наполнилась, селезень уплывает за кадр', 'Кв. 2 · три недели ждал воду: встал — и сел обратно',
              'Кв. 3 · гора посуды: отмыта одна тарелка')
    for i in range(3):
        x0, y0, w, h = 60 + i * 610, 160, 580, 640
        clips += '<clipPath id="cp%d"><rect x="%d" y="%d" width="%d" height="%d" rx="16"/></clipPath>' % (i, x0, y0, w, h)
        cx, cy = x0 + w / 2, y0 + h / 2
        b = [tiles_bg(x0, y0, w, h, ('mint', 'blue', 'mustard')[i]), R(x0, y0 + h - 90, w, 90, '#6B5B4B')]
        if i == 0:
            b.append(bath(cx - 30, cy + 110, 400, True))
            b.append(Pa(dd('M', cx - 215, cy + 40, 'q', -40, 90, -14, 220), stroke=P['water'], stroke_width=16, stroke_linecap='round'))
            b.append(duck(x0 + w - 40, cy - 10, 1.3))
            for k in range(3):
                b.append(Ln(x0 + w - 150 - k * 30, cy - 30 + k * 18, x0 + w - 115 - k * 30, cy - 30 + k * 18, '#FFFFFF', 5, opacity='.7'))
        elif i == 1:
            b.append(R(cx + 150, cy - 250, 110, 130, '#FFFFFF', stroke=P['ol'], stroke_width=3))
            b.append(T(cx + 205, cy - 170, '21', 56, P['red'], weight='bold', anchor='middle'))
            b.append(Ln(cx + 165, cy - 232, cx + 245, cy - 140, P['ink'], 4) + Ln(cx + 245, cy - 232, cx + 165, cy - 140, P['ink'], 4))
            b.append(toilet(cx - 20, cy + 150, 300, True))
            b.append(R(cx - 110, cy - 110, 110, 150, '#FFFFFF', rx=20, stroke=P['ol'], stroke_width=4))
            b.append(R(cx - 110, cy + 30, 110, 110, '#35507A', rx=12, stroke=P['ol'], stroke_width=4))
            b.append(C(cx - 55, cy - 160, 48, P['skin'], stroke=P['ol'], stroke_width=4))
            b.append(Pa(dd('M', cx - 95, cy - 185, 'q', 40, -45, 80, 0), stroke='#3A2A1E', stroke_width=12, stroke_linecap='round'))
            b.append(C(cx - 70, cy - 165, 5, P['ol']) + C(cx - 40, cy - 165, 5, P['ol']) + Ln(cx - 68, cy - 138, cx - 42, cy - 138, P['ol'], 4))
            b.append(R(cx - 200, cy - 60, 90, 110, '#E8E2CF', stroke=P['ol'], stroke_width=3))
            b.append(arrow(cx + 90, cy + 20, cx + 90, cy - 70, P['cream'], 8) + arrow(cx + 130, cy - 70, cx + 130, cy + 20, P['cream'], 8))
        else:
            b.append(sink(cx - 10, cy + 170, 300, True))
            for k in range(8):
                b.append(E(cx - 60 + (k % 2) * 8, cy + 90 - k * 26, 95, 18, 'url(#pc)', stroke=P['ol'], stroke_width=3))
            b.append(E(cx + 150, cy - 40, 72, 72, 'url(#pc)', stroke=P['ol'], stroke_width=4) + E(cx + 150, cy - 40, 42, 42, 'none', stroke='#D5DBE3', stroke_width=3))
            for sx, sy, sr in ((200, -110, 16), (100, -90, 10), (205, 10, 11)):
                b.append(Pg([(cx + sx, cy + sy - sr), (cx + sx + sr * .3, cy + sy - sr * .3), (cx + sx + sr, cy + sy), (cx + sx + sr * .3, cy + sy + sr * .3),
                             (cx + sx, cy + sy + sr), (cx + sx - sr * .3, cy + sy + sr * .3), (cx + sx - sr, cy + sy), (cx + sx - sr * .3, cy + sy - sr * .3)], '#FFFFFF'))
        s.append(G(''.join(b), clip_path='url(#cp%d)' % i))
        s.append(R(x0, y0, w, h, 'none', rx=16, stroke=P['brass'], stroke_width=3))
        for k, ln in enumerate(wrap(titles[i], 30)):
            s.append(T(cx, y0 + h + 60 + k * 44, ln, 34, P['cream'], anchor='middle'))
    return ''.join(s), clips


def gallery():
    s = [R(0, 0, 1920, 1640, '#1E2428'), T(60, 86, 'Элементы поля и героя', 54, P['cream'], weight='bold'),
         T(60, 130, 'Cel-shading, контур #2B2118. Закреплённое темнее и на хомуте, подвижная латунь — яркая. Н — штуцер с витками, В — шестигранное гнездо.', 29, '#AEB9C0')]

    def tile(col, row, label, fn, span=1):
        x0, y0, w, th = 60 + col * 226, 164 + row * 318, span * 226 - 16, 294
        s.append(R(x0, y0, w, th, '#2A3136', rx=14))
        s.append(R(x0 + 10, y0 + 10, w - 20, 72, P['wash']))
        s.append(R(x0 + 10, y0 + 82, w - 20, th - 158, P['paint']))
        s.append(R(x0 + 10, y0 + 78, w - 20, 8, P['stripe']))
        s.append(fn(x0 + w / 2, y0 + 124))
        for k, ln in enumerate(wrap(label, 17 * span)):
            s.append(T(x0 + w / 2, y0 + th - 44 + k * 30, ln, 27, P['cream'], anchor='middle'))

    def wallblock(tl):
        return lambda x, y: walls(['#..', '##.', '###'], x - 78, y - 78, 52, tl)
    r0 = [('Стена · кв. 1, мятная', wallblock('mint')), ('Стена · кв. 2, голубая', wallblock('blue')),
          ('Стена · кв. 3, горчичная', wallblock('mustard')), ('Слив', lambda x, y: drain(x, y, 104)),
          ('Стояк · выход В', lambda x, y: source(x, y, 104, {'right': 'V'}, False, False)),
          ('Глухой отвод · Н', lambda x, y: stub(x, y, 104, 'right', 'N', 'left')),
          ('Глухой отвод · В', lambda x, y: stub(x, y, 104, 'down', 'V', 'up')), ('Фаянс', lambda x, y: porcelain(x, y, 104))]
    r1 = [('Ванна · сухая', lambda x, y: fixture(x, y, 104, 'bath', 'left', 'N', False)), ('Ванна · с водой', lambda x, y: fixture(x, y, 104, 'bath', 'left', 'N', True)),
          ('Унитаз · сухой', lambda x, y: fixture(x, y, 104, 'toilet', 'left', 'N', False)), ('Унитаз · с водой', lambda x, y: fixture(x, y, 104, 'toilet', 'left', 'N', True)),
          ('Мойка · сухая', lambda x, y: fixture(x, y, 104, 'sink', 'left', 'N', False)), ('Мойка · с водой', lambda x, y: fixture(x, y, 104, 'sink', 'left', 'N', True)),
          ('Протечка без напора: капает', lambda x, y: stub(x, y - 20, 90, 'down', 'V', 'up') + drop(x, y + 50, 13) + drop(x, y + 88, 9)),
          ('Струя под напором (кв. 7–10)', lambda x, y: stub(x, y + 50, 90, 'up', 'V', 'down') + jet(x, y + 2, 118, 90))]
    r2 = [('Муфта (кв. 4+)', lambda x, y: fitting(x, y, 104, {'left': 'V', 'right': 'N'})), ('Угольник', lambda x, y: fitting(x, y, 104, {'left': 'V', 'down': 'N'})),
          ('Тройник', lambda x, y: fitting(x, y, 104, {'left': 'V', 'right': 'N', 'down': 'N'})), ('Заглушка', lambda x, y: fitting(x, y, 104, {'left': 'V'})),
          ('Свинчивание: пух ленты', lambda x, y: port(x + 52, y, 104, 'left', 'V', True) + heel((x - 40, y), 'right', 104, True, True)),
          ('Голова кусает резьбу', lambda x, y: port(x + 46, y, 104, 'left', 'N', True) + head((x - 46, y), 'right', 104, True, True)),
          ('Кнопки: отмена, заново', lambda x, y: icon('undo', x - 55, y, 44) + icon('restart', x + 55, y, 44)),
          ('Кнопки: подсказка, меню', lambda x, y: icon('hint', x - 55, y, 44) + icon('menu', x + 55, y, 44))]
    for row, items in enumerate((r0, r1, r2)):
        for col, (lab, fn) in enumerate(items):
            tile(col, row, lab, fn)
    r3 = [('Голова ходит, ноги спят: пальцы поджаты', lambda x, y: lapidus([(x - 96, y), (x, y), (x + 96, y)], 96, 2, 4)),
          ('Сжат до 2: рёбра гуще. Ходят ноги', lambda x, y: lapidus([(x + 48, y), (x - 48, y)], 96, 2, 4, active='heel')),
          ('Растянут до 4 с изгибом: рёбра реже', lambda x, y: lapidus([(x - 126, y + 36), (x - 42, y + 36), (x + 42, y + 36), (x + 42, y - 48)], 84, 2, 4)),
          ('Вода идёт насквозь: стояк → Лапидус → ванна', lambda x, y: source(x - 168, y, 84, {'right': 'V'}, False, False)
           + lapidus([(x - 84, y), (x, y), (x + 84, y)], 84, 2, 4, wet=True, screwed=(True, True), ring=False) + fixture(x + 168, y, 84, 'bath', 'left', 'N', True))]
    for col, (lab, fn) in enumerate(r3):
        tile(col * 2, 3, lab, fn, span=2)
    s.append(T(60, 1620, 'Все макеты — стартовые позиции и примеры состояний; решений уровней здесь нет.', 28, '#8E9AA3'))
    return ''.join(s)


def main():
    raw = subprocess.check_output(['luajit', 'tools/dumplevels.lua', '1', '2', '3'], cwd=ROOT)
    L = json.loads(raw.decode('utf-8'))
    for lv in L:
        for ob in lv['objects']:
            if ob['kind'] == 'lapidus' and ob.get('head') == 1 and len(ob['cells']) > 1:
                ob['cells'] = list(reversed(ob['cells']))
    jobs = [('01_gallery', 1920, 1640, gallery), ('02_level1', 1920, 1080, lambda: level_screen(L[0])),
            ('03_level2', 1920, 1080, lambda: level_screen(L[1])), ('04_level3', 1920, 1080, lambda: level_screen(L[2], moves=3, overlay=toast('Голова по мылу скользит'))),
            ('05_menu', 1920, 1080, menu_screen), ('06_select', 1920, 1080, select_screen), ('07_request', 1920, 1080, lambda: request_screen(L[0])),
            ('08_hint', 1920, 1080, lambda: hint_screen(L[1])), ('09_act', 1920, 1080, lambda: act_screen(L[0])),
            ('10_passport', 1920, 1080, passport_screen), ('11_washed', 1920, 1080, lambda: washed_screen(L[0])), ('12_scenes', 1920, 1080, scenes_screen)]
    for name, w, h, fn in jobs:
        try:
            res = fn()
            body, extra = res if isinstance(res, tuple) else (res, '')
            render(name, w, h, body, extra)
            print('ok', name)
        except Exception:
            print('FAIL', name)
            traceback.print_exc()


if __name__ == '__main__':
    main()
