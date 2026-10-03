#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/export_ui.py — карточки правил (паспорт), экран дома и двери квартир, заставка меню — из игровых спрайтов
(Blender) и Лапидуса, нарисованного движком (art/hero_png.py). Вёрстка и тексты — прежние (art/screens2.py).
   python3 art/export_ui.py"""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2, hero_png
from gen2 import defs2

hero_png.use_in(screens2)
OUT = os.path.join(gen2.ROOT, 'assets', 'gfx')
TMP = os.path.join(gen2.ROOT, 'build', 'gfx_svg')
os.makedirs(TMP, exist_ok=True)
DEFS = gen.DEFS + defs2(120, 0, 0, 'mint') + screens2.tile_pat('tpM', 120, 'mint') + screens2.tile_pat('tpB', 120, 'blue') + screens2.tile_pat('tpY', 120, 'mustard')


def out(name, body, w, h, extra='', jpeg=False):
    svg = os.path.join(TMP, name + '.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>'
                % (w, h, w, h, DEFS, extra, body))
    png = os.path.join(OUT, name + '.png')
    subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), '-o', png, svg], check=True)
    if jpeg:
        subprocess.run(['convert', png, '-quality', '88', os.path.join(OUT, name + '.jpg')], check=True)
        os.remove(png)
    print(name)


# меню: фон — Blender (art/blender/menu.py: стена, трубы, стояк, вентиль, лампа), поверх — луч, бирка, Лапидус, логотип
import base64, math
from gen import G, R, C, T, Ln, Pg
from gen2 import Q
bg = os.path.join(gen2.ROOT, 'build', 'menu', 'menu_bg.png')
if not os.path.exists(bg):
    os.makedirs(os.path.dirname(bg), exist_ok=True)
    subprocess.run(['xvfb-run', '-a', 'blender', '-b', '-P', os.path.join(gen2.ROOT, 'art', 'blender', 'menu.py'), '--', bg], check=True, capture_output=True)
O = Q['ol']
m = ['<image x="0" y="0" width="1920" height="1080" xlink:href="data:image/png;base64,%s"/>' % base64.b64encode(open(bg, 'rb').read()).decode(),
     Pg([(960, 60), (470, 1080), (1450, 1080)], 'url(#bulb)'),
     Ln(520, 520, 600, 626, '#8A8A8A', 3),
     G(R(560, 620, 260, 104, '#E9DFB8', rx=8, stroke=O, stroke_width=3) + T(690, 664, 'ГЛАВНЫЙ', 34, O, weight='bold', anchor='middle')
       + T(690, 704, 'ВЕНТИЛЬ ДОМА', 32, O, weight='bold', anchor='middle'), filter='url(#dsh)', transform='rotate(6 690 672)'),
     screens2.hero([(472, 990), (612, 990), (612, 850), (752, 850)], 140, 2, 5, active='head', ring=False),
     gen.logo(522, 300, 1.12),
     T(960, 548, 'НИ КАПЛИ', 76, Q['cream'], weight='bold', anchor='middle', letter_spacing='14', stroke=O, stroke_width=3, paint_order='stroke')]
out('scr_menu', ''.join(m), 1920, 1080, screens2.BASE, jpeg=True)
for cname, fn in screens2.CARDS.items():
    body, extra = fn()
    out(cname, body, 564, 584 if cname == 'card06' else 380, extra)
hero_png.FX_CARD = False
body, extra = screens2.select2(solved=(), opened=())
out('scr_building', body, 1920, 1080, extra, jpeg=True)
NL = tuple(range(1, len(screens2.L) + 1))
for tag, sv, op in (('solved', NL, ()), ('open', (), NL)):
    body, extra = screens2.select2(solved=sv, opened=op)
    out('tmp_bld_' + tag, body, 1920, 1080, extra)
    for apt in NL:
        fl, left = (apt + 1) // 2, apt % 2 == 1
        x0, y0 = (580 if left else 990), 940 - fl * 150 + 10
        subprocess.run(['convert', os.path.join(OUT, 'tmp_bld_%s.png' % tag), '-crop', '366x146+%d+%d' % (x0 - 8, y0 - 8), '+repage',
                        os.path.join(OUT, 'apt%d_%s.png' % (apt, tag))], check=True)
    os.remove(os.path.join(OUT, 'tmp_bld_%s.png' % tag))
