#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/export.py — выгрузка утверждённого арта в ресурсы игры assets/gfx (фаза 3).

Спрайты рисуются при клетке 240 px (вдвое крупнее максимальной клетки 120) на холсте 480×480
с центром клетки в (240, 240); движок масштабирует их под клетку уровня. Фоны квартир и экраны —
1920×1080 (виртуальное разрешение игры). Текст, который меняется, рисует движок."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2, parts
from gen import R, C, G, T, Ln
from gen2 import Q, frame, headL, heelL, bath2, toilet2, sink2, porcelain2, port2, fluff2, button2, defs2

OUT = os.path.join(gen2.ROOT, 'assets', 'gfx')
TMP = os.path.join(gen2.ROOT, 'build', 'gfx_svg')
os.makedirs(OUT, exist_ok=True)
os.makedirs(TMP, exist_ok=True)
DEFS = gen.DEFS + defs2(120, 0, 0, 'mint') + screens2.tile_pat('tpM', 120, 'mint') + screens2.tile_pat('tpB', 120, 'blue') + screens2.tile_pat('tpY', 120, 'mustard')
CR = 240
made = []


def out(name, body, w, h, extra='', base=True):
    svg = os.path.join(TMP, name + '.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>'
                % (w, h, w, h, DEFS if base else gen.DEFS, extra, body))
    subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), '-o', os.path.join(OUT, name + '.png'), svg], check=True)
    made.append(name)


def sprite(name, body):
    out(name, G(body, filter='url(#dsh)'), 2 * CR, 2 * CR)


X = Y = CR
# приборы (порт слева, как в каноне; сам порт — отдельным спрайтом), фаянс
def fit_box(body, sw=.80, sh=.92):
    """Прибор целиком в прямоугольник sw×sh клетки вокруг центра (03.10: приборы шире клетки залезали на стены и на свою же
    подводку). Габарит меряется по отрисовке; движок затем сдвигает прибор от входа на 0.07 клетки."""
    svg = os.path.join(TMP, '_fit.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d"><defs>%s</defs>%s</svg>'
                % (4 * CR, 4 * CR, DEFS, '<g transform="translate(%d %d)">%s</g>' % (CR, CR, body)))
    png = os.path.join(TMP, '_fit.png')
    subprocess.run(['rsvg-convert', '-o', png, svg], check=True)
    w, h, x, y = map(int, subprocess.run(['convert', png, '-trim', '-format', '%w %h %X %Y', 'info:'], capture_output=True, text=True).stdout.replace('+', ' ').split())
    bx, by = x - CR + w / 2, y - CR + h / 2                      # центр габарита относительно (X, Y)
    k = min(sw * CR / w, sh * CR / h, 1.0)
    return '<g transform="translate(%s %s) scale(%s) translate(%s %s)">%s</g>' % (X, Y, round(k, 4), round(-bx, 2), round(-by, 2), body)


for what, fn in (('bath', bath2), ('toilet', toilet2), ('sink', sink2), ('washer', gen2.washer2), ('dryer', gen2.dryer2), ('heater', gen2.heater2)):
    for wet in (False, True):
        sprite('fx_%s_%s' % (what, 'wet' if wet else 'dry'), fit_box(fn(X, Y, CR, wet)))
sprite('porcelain', porcelain2(X, Y, CR))
SIG = {'up': 'u', 'right': 'r', 'down': 'd', 'left': 'l'}
for lv in screens2.L:
    for ob in lv['objects']:
        if ob['kind'] == 'fitting':
            sig = ''.join(SIG[d] + ob['ports'][d] for d in ('up', 'right', 'down', 'left') if d in ob['ports'])
            if 'fit_' + sig not in made:
                sprite('fit_' + sig, gen2.fitting2(X, Y, CR, ob['ports']))
for th in ('N', 'V'):
    sprite('port_%s' % th, port2(X, Y, CR, 'right', th, False))
    sprite('port_%s_fixed' % th, port2(X, Y, CR, 'right', th, True))
    sprite('port_%s_fx' % th, parts.port(X, Y, CR, 'right', th, True, .36))  # короткая подводка прибора (не залезает на прибор)
out('foam', parts.foam(X, Y, CR), 2 * CR, 2 * CR)  # протечка — пена у открытой резьбы: центр пены — центр холста
# герой: голова и ноги во всех направлениях, активные и спящие
for dr in ('right', 'left', 'up', 'down'):
    for act in (True, False):
        sprite('head_%s_%s' % (dr, 'on' if act else 'off'), headL((X, Y), dr, CR, act, False))
        sprite('feet_%s_%s' % (dr, 'on' if act else 'off'), heelL((X, Y), dr, CR, act, False))
out('fluff', fluff2(X, Y, CR), 2 * CR, 2 * CR)
out('drop', gen.drop(60, 70, 26), 120, 120)
for k in ('undo', 'restart', 'hint', 'menu'):
    out('btn_%s' % k, button2(k, 72, 72), 144, 144)
out('hud_plate', G(gen.E(130, 90, 112, 76, '#EFEADF', stroke=Q['ol'], stroke_width=5) + gen.E(130, 90, 98, 62, '#1F4E97')
                   + gen.E(130, 90, 90, 54, 'none', stroke='#FFFFFF', stroke_width=4) + C(30, 90, 7, '#B8B2A2', stroke=Q['ol'], stroke_width=2)
                   + C(230, 90, 7, '#B8B2A2', stroke=Q['ol'], stroke_width=2), filter='url(#dsh)'), 260, 180)
out('hud_tag', G(R(10, 24, 300, 76, '#F4EEDC', rx=4, stroke='#B9AF98', stroke_width=2) + R(124, 12, 72, 26, '#E6DDB4', opacity='.85'), filter='url(#dsh)'), 320, 120)
# фоны квартир: кладка, комната, сливы, стояк, крючья (приборы, фаянс, герой — спрайтами)
for lv in screens2.L:
    body, extra, _ = frame(lv, no_lap=True, hud=False, skip=('fixture', 'porcelain', 'fitting'))
    out('lvl%02d' % lv['id'], body, 1920, 1080, extra, base=False)
# экраны
body, extra = screens2.menu2(items=False)
out('scr_menu', body, 1920, 1080, extra)
for cname, fn in screens2.CARDS.items():  # вкладыши новых правил (экран заявки и страницы паспорта)
    body, extra = fn()
    out(cname, body, 564, 584 if cname == 'card06' else 380, extra)
body, extra = screens2.select2(solved=(), opened=())
out('scr_building', body, 1920, 1080, extra)
NL = tuple(range(1, len(screens2.L) + 1))
for tag, sv, op in (('solved', NL, ()), ('open', (), NL)):
    body, extra = screens2.select2(solved=sv, opened=op)
    out('tmp_bld_' + tag, body, 1920, 1080, extra)
    for apt in range(1, len(screens2.L) + 1):
        fl, left = (apt + 1) // 2, apt % 2 == 1
        x0, y0 = (580 if left else 990), 940 - fl * 150 + 10
        subprocess.run(['convert', os.path.join(OUT, 'tmp_bld_%s.png' % tag), '-crop', '366x146+%d+%d' % (x0 - 8, y0 - 8), '+repage',
                        os.path.join(OUT, 'apt%d_%s.png' % (apt, tag))], check=True)
    os.remove(os.path.join(OUT, 'tmp_bld_%s.png' % tag))
# немые сцены: панели 588×648 из листов 1920×1080; номера — НОВЫЕ номера квартир (перестановка 02.10)
def cut_scenes(fn, nums, *args):
    body, extra = fn(*args)
    out('tmp_scenes', body, 1920, 1080, extra)
    for i, apt in enumerate(nums):
        subprocess.run(['convert', os.path.join(OUT, 'tmp_scenes.png'), '-crop', '588x648+%d+156' % (56 + i * 610), '+repage', os.path.join(OUT, 'scene%d.png' % apt)], check=True)
    os.remove(os.path.join(OUT, 'tmp_scenes.png'))


cut_scenes(screens2.scenes2, (1, 2, 7))         # ванна, унитаз, посуда (посуда — «Мыло», с 03.10 кв. 7)
cut_scenes(screens2.scenes45, (4, 3))           # стиралка («Резьба», с 03.10 кв. 4), носок
cut_scenes(screens2.scenes6, (10,))             # колонка и ушанка
cut_scenes(screens2.scenes7_10, (5, 6, 8), 0)   # фонтан, брандспойт, гребёнка (заглушки: кв. 5, 6, 8 переделаны 02–03.10)
cut_scenes(screens2.scenes7_10, (9,), 1)        # опрессовка
note = [R(10, 10, 700, 430, '#FBFAF4', rx=6)] + [Ln(10, 10 + i * 34, 710, 10 + i * 34, '#C4D6EC', 1.5) for i in range(1, 13)]
note += [Ln(10 + i * 34, 10, 10 + i * 34, 440, '#C4D6EC', 1.5) for i in range(1, 21)] + [Ln(90, 10, 90, 440, '#E28A8A', 2.5), R(290, 0, 140, 46, '#E9DFB8', opacity='.9')]
out('note', G(''.join(note), filter='url(#dsh)'), 740, 470)
out('act_paper', G(R(10, 10, 800, 980, '#F3EDDC', rx=6) + R(10, 10, 800, 980, '#000000', filter='url(#grain)', opacity='.18')
                   + C(700, 130, 62, 'none', stroke='#9B6B3A', stroke_width=7, opacity='.25'), filter='url(#dsh)'), 840, 1020)
out('stamp', G(C(160, 160, 150, 'none', stroke='#2B56B8', stroke_width=10) + C(160, 160, 118, 'none', stroke='#2B56B8', stroke_width=4)
               + T(160, 152, 'ВЫПОЛНЕНО', 46, '#2B56B8', weight='bold', anchor='middle') + T(160, 198, 'ЖЭУ № 3', 30, '#2B56B8', weight='bold', anchor='middle'), opacity='.92'), 320, 320)
print('готово спрайтов и фонов: %d' % len(made))
