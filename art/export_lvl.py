#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/export_lvl.py — быстрая выгрузка арта отдельных квартир (полный art/export.py идёт ~2,5 мин).
   python3 art/export_lvl.py 6 [4 3 ...]
Для каждой квартиры: фон lvlNN (сразу в JPEG, как в ресурсах) и недостающие спрайты её деталей fit_*
(существующие не трогает; --force — перерисовать и их);
для кв. 6 и 7 ещё карточки новых правил card06 и card07 (экран заявки). Функции рисования — те же, что в art/export.py."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2
from gen import G
from gen2 import frame, defs2

FORCE = '--force' in sys.argv  # перерисовать и уже существующие спрайты деталей
IDS = [int(a) for a in sys.argv[1:] if a.isdigit()] or [6]
OUT = os.path.join(gen2.ROOT, 'assets', 'gfx')
TMP = os.path.join(gen2.ROOT, 'build', 'gfx_svg')
os.makedirs(TMP, exist_ok=True)
DEFS = gen.DEFS + defs2(120, 0, 0, 'mint') + screens2.tile_pat('tpM', 120, 'mint') + screens2.tile_pat('tpB', 120, 'blue') + screens2.tile_pat('tpY', 120, 'mustard')
CR = 240


def out(name, body, w, h, extra='', base=True, jpeg=False):
    svg = os.path.join(TMP, name + '.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>'
                % (w, h, w, h, DEFS if base else gen.DEFS, extra, body))
    png = os.path.join(OUT, name + '.png')
    subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), '-o', png, svg], check=True)
    if jpeg:
        subprocess.run(['convert', png, '-quality', '88', os.path.join(OUT, name + '.jpg')], check=True)
        os.remove(png)
    print(name)


SIG = {'up': 'u', 'right': 'r', 'down': 'd', 'left': 'l'}
for lv in screens2.L:
    if lv['id'] not in IDS:
        continue
    for ob in lv['objects']:
        if ob['kind'] == 'fitting':
            sig = ''.join(SIG[d] + ob['ports'][d] for d in ('up', 'right', 'down', 'left') if d in ob['ports'])
            if not FORCE and os.path.exists(os.path.join(OUT, 'fit_%s.png' % sig)):
                continue
            out('fit_' + sig, G(gen2.fitting2(CR, CR, CR, ob['ports']), filter='url(#dsh)'), 2 * CR, 2 * CR)
    body, extra, _ = frame(lv, no_lap=True, hud=False, skip=('fixture', 'porcelain', 'fitting'))
    out('lvl%02d' % lv['id'], body, 1920, 1080, extra, base=False, jpeg=True)
for cname, fn in screens2.CARDS.items():  # вкладыши новых правил на экране заявки (card01b/c — страницы паспорта кв. 1)
    if int(cname[4:6]) in IDS:
        body, extra = fn()
        out(cname, body, 564, 380, extra)
