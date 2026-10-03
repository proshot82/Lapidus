#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/misc_compose.py — мелкие спрайты из рендера art/blender/misc.py + слой поверх (узор фаянса, значки кнопок,
белое кольцо таблички), тень → assets/gfx (porcelain, foam, drop, btn_*, hud_plate).
   xvfb-run -a blender -b -P art/blender/misc.py -- build/misc && python3 art/misc_compose.py build/misc"""
import json, math, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2
from gen import C, E, Ln, n
from gen2 import button2

SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(gen2.ROOT, 'build', 'misc')
OUT = os.path.join(gen2.ROOT, 'assets', 'gfx')
AN = json.load(open(os.path.join(SRC, 'misc_anchors.json')))


def run(*a):
    subprocess.run(a, check=True)


def overlay(raw, svg_body, w, h, dst, shadow=(5, 5, 8, .45)):
    svg = os.path.join(SRC, '_ov.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"><defs>%s</defs>%s</svg>' % (w, h, gen.DEFS, svg_body))
    ov = os.path.join(SRC, '_ov.png')
    run('rsvg-convert', '-w', str(w), '-h', str(h), '-o', ov, svg)
    comp = os.path.join(SRC, '_c.png')
    run('convert', raw, ov, '-composite', comp)
    if shadow:
        b, dx, dy, op = shadow
        run('convert', comp, '(', '+clone', '-fill', 'black', '-colorize', '100', '-channel', 'A', '-evaluate', 'multiply', str(op),
            '+channel', '-blur', '0x%s' % b, '-roll', '+%d+%d' % (dx, dy), ')', '+swap', '-background', 'none', '-composite', dst)
    else:
        run('cp', comp, dst)
    print(os.path.basename(dst))


# фаянс: синие полосы и цветочки (гжель), как в каноне
a = AN['porcelain']
BL = '#2F5E9E'
s = []
(lx, _), (rx, _) = a['left'], a['right']
for key in ('band1', 'band2'):
    x, y = a[key]
    s.append(Ln(lx + 6, y, rx - 6, y, BL, 5))
x, y = a['mid']
for i in range(5):
    fx = lx + (rx - lx) * (i + .5) / 5
    for ang in (0, 90):
        s.append(E(fx, y, 10, 4, BL, transform='rotate(%d %s %s)' % (ang + 45, n(fx), n(y))))
    s.append(C(fx, y, 3, '#FFFFFF'))
overlay(os.path.join(SRC, 'porcelain_raw.png'), ''.join(s), 480, 480, os.path.join(OUT, 'porcelain.png'))
overlay(os.path.join(SRC, 'foam_raw.png'), '', 480, 480, os.path.join(OUT, 'foam.png'), shadow=None)
overlay(os.path.join(SRC, 'drop_raw.png'), '', 120, 120, os.path.join(OUT, 'drop.png'), shadow=None)
# кнопки: значок из прежнего рисунка (без трёх кругов — тени, ободка и поля)
for k in ('undo', 'restart', 'hint', 'menu'):
    body = button2(k, 72, 72)
    body = re.sub(r'<circle[^>]*/>', '', body, count=3)
    overlay(os.path.join(SRC, 'button_raw.png'), body, 144, 144, os.path.join(OUT, 'btn_%s.png' % k), shadow=(3, 3, 6, .4))
# табличка: тонкое белое кольцо по синему полю
(cx, cy), (ex, ey) = AN['plate']['ring']
overlay(os.path.join(SRC, 'plate_raw.png'), E(cx, cy, abs(ex - cx) * 1.0, abs(ey - cy) * 1.0, 'none', stroke='#FFFFFF', stroke_width=4),
        260, 180, os.path.join(OUT, 'hud_plate.png'))
