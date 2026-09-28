#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/export6.py — быстрая выгрузка только того, что меняется у кв. 6: фон lvl06 и спрайты её деталей.
Использует те же функции, что art/export.py (полный экспорт ~2,5 мин)."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2
from gen import G
from gen2 import frame, defs2

OUT = os.path.join(gen2.ROOT, 'assets', 'gfx')
TMP = os.path.join(gen2.ROOT, 'build', 'gfx_svg')
os.makedirs(TMP, exist_ok=True)
DEFS = gen.DEFS + defs2(120, 0, 0, 'mint') + screens2.tile_pat('tpM', 120, 'mint') + screens2.tile_pat('tpB', 120, 'blue') + screens2.tile_pat('tpY', 120, 'mustard')
CR = 240


def out(name, body, w, h, extra='', base=True):
    svg = os.path.join(TMP, name + '.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>'
                % (w, h, w, h, DEFS if base else gen.DEFS, extra, body))
    subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), '-o', os.path.join(OUT, name + '.png'), svg], check=True)
    print(name)


SIG = {'up': 'u', 'right': 'r', 'down': 'd', 'left': 'l'}
for lv in screens2.L:
    if lv['id'] != 6:
        continue
    for ob in lv['objects']:
        if ob['kind'] == 'fitting':
            sig = ''.join(SIG[d] + ob['ports'][d] for d in ('up', 'right', 'down', 'left') if d in ob['ports'])
            out('fit_' + sig, G(gen2.fitting2(CR, CR, CR, ob['ports']), filter='url(#dsh)'), 2 * CR, 2 * CR)
    body, extra, _ = frame(lv, no_lap=True, hud=False, skip=('fixture', 'porcelain', 'fitting'))
    out('lvl06', body, 1920, 1080, extra, base=False)
