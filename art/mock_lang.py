#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/mock_lang.py — макет визуального языка «закреплённое — подвижное — прикрученное» для §8 DESIGN (на утверждение).
Верхний ряд — как сейчас, нижний — предложение. Выход: build/ui/mock_lang.png."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2
from gen import R, C, E, G, T, Ln
from gen2 import Q, fitting2, stub2, plug2, port2, orient

ROOT = gen2.ROOT
OUT = os.path.join(ROOT, 'build', 'ui')
os.makedirs(OUT, exist_ok=True)
W, H, c = 1920, 1080, 150
O = Q['ol']

# сталь для всего, что не сдвинется никогда: чугун сети и «окаменевшие» детали
STEEL = ('<filter id="steel" color-interpolation-filters="sRGB"><feColorMatrix type="saturate" values="0.08"/>'
         '<feComponentTransfer><feFuncR type="linear" slope="0.78" intercept="0.02"/><feFuncG type="linear" slope="0.82" intercept="0.03"/>'
         '<feFuncB type="linear" slope="0.9" intercept="0.06"/></feComponentTransfer></filter>')


def shadow(cx, cy):
    """Подвижное: мягкая тень на полу под деталью — видно, что она просто лежит."""
    return E(cx + .06 * c, cy + .40 * c, .42 * c, .09 * c, '#000000', opacity='.35', filter='url(#bl8)')


def clamp(cx, cy, dr):
    """Хомут к стене: две скобы с болтами за деталью (рисуется до неё)."""
    band = (R(cx - .07 * c, cy - .52 * c, .14 * c, 1.04 * c, 'url(#ironH)', rx=.03 * c, stroke=O, stroke_width=c * .03)
            + C(cx, cy - .44 * c, .035 * c, '#C9CFD6', stroke=O, stroke_width=c * .015)
            + C(cx, cy + .44 * c, .035 * c, '#C9CFD6', stroke=O, stroke_width=c * .015))
    return orient(band, dr, cx, cy)


def fluff(cx, cy):
    return ''.join(C(cx + dx * c, cy + dy * c, r * c, '#FFFFFF', opacity='.95', stroke='#D8D8D0', stroke_width=2)
                   for dx, dy, r in ((-.05, -.20, .06), (.02, -.24, .05), (0, -.12, .05), (-.03, .18, .06), (.04, .23, .05), (.0, .1, .045)))


def cell(x, y, label, sub, body):
    return (R(x, y, 380, 360, '#C9D8CF', rx=18, stroke=O, stroke_width=4)
            + R(x, y + 250, 380, 110, '#9FB5A8', rx=0) + Ln(x, y + 250, x + 380, y + 250, O, 3)
            + body + T(x + 190, y + 400, label, 34, '#F4EEDC', weight='bold', anchor='middle')
            + T(x + 190, y + 440, sub, 28, '#C9D3DC', anchor='middle'))


def row(y, proposed):
    xs = [120, 560, 1000, 1440]
    out = []
    # 1. Сеть: отвод-крюк на стене
    cx, cy = xs[0] + 190, y + 150
    body = stub2(cx - 40, cy, c, 'right', 'V', 'left')
    out.append(cell(xs[0], y, 'сеть', 'не двигается никогда', G(body, filter='url(#steel)') if proposed else body))
    # 2. Подвижная деталь на полу
    cx, cy = xs[1] + 190, y + 190
    body = fitting2(cx, cy, c, {'left': 'V', 'right': 'V'})
    out.append(cell(xs[1], y, 'деталь', 'лежит, можно толкать', (shadow(cx, cy) + G(body, filter='url(#dsh)')) if proposed else body))
    # 3. Деталь, прикрученная к сети (стала неподвижной)
    cx, cy = xs[2] + 230, y + 150
    net = stub2(cx - c, cy, c, 'right', 'N', 'left')
    piece = fitting2(cx, cy, c, {'left': 'V', 'right': 'N'})
    if proposed:
        body = G(net, filter='url(#steel)') + clamp(cx + .25 * c, cy, 'right') + G(piece, filter='url(#steel)') + fluff(cx - .5 * c, cy)
    else:
        body = net + piece
    out.append(cell(xs[2], y, 'прикручена к сети', 'теперь тоже сеть', body))
    # 4. Резьба Н и В рядом
    cx, cy = xs[3] + 190, y + 150
    k = 1.35 if proposed else .9  # предложение: резьба крупнее, чтобы Н и В читались на телефоне
    n_ = G(port2(cx - 190, cy - 55, c * k, 'right', 'N'))
    v_ = G(port2(cx - 60, cy + 60, c * k, 'right', 'V'))
    lab = (T(cx + 120, cy - 40, 'Н', 40, O, weight='bold') + T(cx + 140, cy + 75, 'В', 40, O, weight='bold')) if proposed else ''
    out.append(cell(xs[3], y, 'резьба Н и В', 'штуцер и гнездо', n_ + v_ + lab))
    return ''.join(out)


body = (R(0, 0, W, H + 60, '#2A2622')
        + T(60, 70, 'Сейчас: всё латунное, закреплённое чуть темнее', 40, '#F6DB8A', weight='bold')
        + row(100, False)
        + T(60, 620, 'Предложение: сталь — не сдвинется никогда; латунь с тенью — лежит; прикрутилась к сети — «окаменела»', 36, '#F6DB8A', weight='bold')
        + row(650, True))
svg = os.path.join(OUT, 'mock_lang.svg')
with open(svg, 'w', encoding='utf-8') as f:
    f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s%s</defs>%s</svg>'
            % (W, H + 60, W, H + 60, gen.DEFS, gen2.defs2(c, 0, 0, 'mint'), STEEL, body))
subprocess.run(['rsvg-convert', '-o', os.path.join(OUT, 'mock_lang.png'), svg], check=True)
print('build/ui/mock_lang.png')
