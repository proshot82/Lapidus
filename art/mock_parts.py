#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/mock_parts.py — сравнение деталей «было / стало» на сетке клеток (границы клеток видны): build/ui/mock_parts.png."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, parts
from gen import R, Ln, T, G

OUT = os.path.join(gen2.ROOT, 'build', 'ui'); os.makedirs(OUT, exist_ok=True)
c = 150
W, H = 1920, 1200
ITEMS = [('муфта В–В', {'left': 'V', 'right': 'V'}), ('ниппель Н–Н', {'left': 'N', 'right': 'N'}), ('переходник В–Н', {'left': 'V', 'right': 'N'}),
         ('угольник', {'left': 'V', 'up': 'N'}), ('угольник В–В', {'right': 'V', 'down': 'V'}), ('тройник', {'up': 'V', 'down': 'V', 'left': 'N'}), ('заглушка Н', {'left': 'N'}), ('колпачок В', {'right': 'V'})]


def grid(x0, y0, k):
    s = []
    for i in range(k + 1):
        s.append(Ln(x0 + i * c, y0, x0 + i * c, y0 + c, '#C9C2B0', 2))
    s.append(Ln(x0, y0, x0 + k * c, y0, '#C9C2B0', 2) + Ln(x0, y0 + c, x0 + k * c, y0 + c, '#C9C2B0', 2))
    return ''.join(s)


body = [R(0, 0, W, H, '#3A4A44')]
for row, (title, fn) in enumerate((('было', gen2.fitting2_old), ('стало', parts.fitting))):
    y0 = 80 + row * 330
    body.append(T(40, y0 - 20, title, 40, '#F6DB8A', weight='bold'))
    x0 = 40
    body.append(R(x0, y0, len(ITEMS) * (c + 80), c, '#5D7268'))
    for i, (name, pts) in enumerate(ITEMS):
        x = x0 + i * (c + 80)
        body.append(grid(x, y0, 1))
        body.append(G(fn(x + c / 2, y0 + c / 2, c, pts), filter='url(#dsh)'))
        body.append(T(x + c / 2, y0 + c + 40, name, 26, '#F4EEDC', anchor='middle'))
# слив было / стало и цепочка стояк — переходник — муфта
y0 = 760
body.append(T(40, y0 - 20, 'слив: было / стало;  сборка в ряд (сталь — уже прикручено)', 34, '#F6DB8A', weight='bold'))
body.append(G(gen2.drain2(40 + c / 2, y0 + c / 2, c, y0 + 2 * c)) + G(parts.drain(260 + c / 2, y0 + c / 2, c, y0 + 2 * c)))
x = 560
body.append(grid(x, y0, 4))
body.append(G(gen2.source2(x + c / 2, y0 + c / 2, c, {'right': 'N'}, top=y0 - 40, bot=y0 + 2 * c), filter='url(#dsh)'))
body.append(G(parts.fitting(x + 1.5 * c, y0 + c / 2, c, {'left': 'V', 'right': 'N'}, fixed=True), filter='url(#dsh)'))
body.append(G(parts.fitting(x + 2.5 * c, y0 + c / 2, c, {'left': 'V', 'right': 'V'}, fixed=True), filter='url(#dsh)'))
body.append(G(gen2.sink2(x + 3.5 * c, y0 + c / 2, c), filter='url(#dsh)'))
svg = os.path.join(OUT, 'mock_parts.svg')
open(svg, 'w', encoding='utf-8').write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>'
                                       % (W, H, W, H, gen.DEFS, gen2.defs2(c, 0, 0, 'mint'), ''.join(body)))
subprocess.run(['rsvg-convert', '-o', os.path.join(OUT, 'mock_parts.png'), svg], check=True)
print('build/ui/mock_parts.png')
