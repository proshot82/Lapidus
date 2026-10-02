#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/screens2.py — все макеты в утверждённом стиле (стиль-кадр gen2): три квартиры, элементы, экраны."""
import json, math, os, random, subprocess, sys, traceback
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen
from gen import n, R, C, E, Ln, Pg, Pa, G, T, dd, wrap, TILE, HAND
import gen2
from gen2 import (Q, frame, headL, heelL, hero, source2, stub2, port2, bath2, toilet2, sink2, porcelain2, fitting2, drain2, defs2,
                  button2, fluff2)

OUT = os.path.join(gen2.ROOT, 'build', 'review2')
_IDS = [str(i) for i in range(1, 11) if os.path.exists(os.path.join(gen2.ROOT, 'levels', '%02d.lua' % i))]
L = json.loads(subprocess.check_output(['luajit', 'tools/dumplevels.lua'] + _IDS, cwd=gen2.ROOT).decode('utf-8'))
for lv in L:
    for ob in lv['objects']:
        if ob['kind'] == 'lapidus' and ob.get('head') == 1 and len(ob['cells']) > 1:
            ob['cells'] = list(reversed(ob['cells']))
INK, O = '#23304E', Q['ol']


def tile_pat(pid, c, tile):
    base, grout, hi = TILE[tile]
    h = c / 2
    return ('<pattern id="%s" patternUnits="userSpaceOnUse" width="%s" height="%s">' % (pid, n(h), n(h)) + R(0, 0, h, h, grout)
            + R(c * .022, c * .022, h - c * .044, h - c * .044, base, rx=c * .05) + Ln(c * .07, c * .07, h - c * .13, c * .07, hi, c * .03, opacity='.9') + '</pattern>')


# «окаменевшая» деталь (прикручена к сети): латунь → холодная сталь, тот же фильтр — шейдер в game/board.lua
STEEL = ('<filter id="steel" color-interpolation-filters="sRGB"><feColorMatrix type="saturate" values="0.08"/>'
         '<feComponentTransfer><feFuncR type="linear" slope="0.78" intercept="0.02"/><feFuncG type="linear" slope="0.82" intercept="0.03"/>'
         '<feFuncB type="linear" slope="0.9" intercept="0.06"/></feComponentTransfer></filter>')
BASE = STEEL + defs2(120, 0, 0, 'mint') + tile_pat('tpM', 120, 'mint') + tile_pat('tpB', 120, 'blue') + tile_pat('tpY', 120, 'mustard')


def render(name, body, extra, w=1920, h=1080):
    p = os.path.join(OUT, name + '.svg')
    with open(p, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s%s</defs>%s</svg>'
                % (w, h, w, h, gen.DEFS, extra, body))
    subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), '-o', os.path.join(OUT, name + '.png'), p], check=True)


def plate(x, y, w, h, body=''):
    return G(R(x, y, w, h, Q['plate'], rx=16, stroke='#8E6819', stroke_width=4) + R(x + 7, y + 7, w - 14, h - 14, 'none', rx=11, stroke='#C99A2E', stroke_width=1.5, opacity='.5')
             + ''.join(C(px, py, 5, '#8E8A80') for px in (x + 16, x + w - 16) for py in (y + 16, y + h - 16)) + body, filter='url(#dsh)')


def toast2(msg):
    w = 90 + len(msg) * 18
    return plate(960 - w / 2, 956, w, 84, T(960, 1011, msg, 40, Q['cream'], anchor='middle'))


def level(i, moves=0, active='head', overlay=''):
    body, extra, _ = frame(L[i], moves, active)
    return body + overlay, extra


# ---------------------------------------------------------------- экраны поверх квартир

def request2():
    body, extra = level(0)
    note = [R(610, 300, 700, 430, '#FBFAF4', rx=6)]
    note += [Ln(610, 300 + i * 34, 1310, 300 + i * 34, '#C4D6EC', 1.5) for i in range(1, 13)]
    note += [Ln(610 + i * 34, 300, 610 + i * 34, 730, '#C4D6EC', 1.5) for i in range(1, 21)]
    note.append(Ln(690, 300, 690, 730, '#E28A8A', 2.5))
    note += [T(720, 420 + i * 82, ln, 64, '#1D3A8F', font=HAND) for i, ln in enumerate(wrap(L[0]['texts']['request'], 22))]
    note.append(T(1270, 700, '— жилец кв. 1', 40, '#1D3A8F', font=HAND, anchor='end'))
    note.append(R(890, 282, 140, 46, '#E9DFB8', opacity='.9', transform='rotate(-4 960 305)'))
    over = (R(0, 0, 1920, 1080, '#000000', opacity='.55') + G(''.join(note), filter='url(#dsh)', transform='rotate(-2 960 515)')
            + T(960, 250, 'ЗАЯВКА', 46, Q['cream'], weight='bold', anchor='middle', letter_spacing='6') + T(960, 822, 'любая клавиша — к работе', 32, '#F6DB8A', anchor='middle'))
    return body + over, extra


def hint2():
    body, extra = level(1, moves=7)
    x0, y0, w, h = 330, 690, 1260, 360
    hx, hy = x0 + 80, y0 + 94
    inner = [Pa(dd('M', hx - 22, hy - 34, 'Q', hx - 48, hy, hx - 22, hy + 34), stroke=O, stroke_width=26, stroke_linecap='round'),
             Pa(dd('M', hx - 22, hy - 34, 'Q', hx - 48, hy, hx - 22, hy + 34), stroke='#D1A238', stroke_width=16, stroke_linecap='round'),
             R(hx - 38, hy - 56, 36, 26, 'url(#cylG)', rx=9, stroke=O, stroke_width=3, transform='rotate(-28 %s %s)' % (n(hx - 20), n(hy - 43))),
             R(hx - 38, hy + 30, 36, 26, 'url(#cylG)', rx=9, stroke=O, stroke_width=3, transform='rotate(28 %s %s)' % (n(hx - 20), n(hy + 43))),
             T(x0 + 150, y0 + 70, 'Горячая линия управляющей компании', 36, '#F6DB8A', weight='bold'),
             T(x0 + w - 36, y0 + 52, 'ожидание: до окончания работ', 26, '#9FB0B8', anchor='end')]
    inner += [T(x0 + 150, y0 + 132 + i * 50, ln, 40, Q['cream']) for i, ln in enumerate(wrap(L[1]['texts']['hints'][0], 58))]
    for i, lab in enumerate(('1 · Суть', '2 · Я в тупике?', '3 · Вызвать мастера')):
        bx, by = x0 + 150 + i * 354, y0 + 268
        inner.append(R(bx, by, 330, 64, 'url(#cylG)' if i == 0 else '#3A342D', rx=32, stroke=O if i == 0 else '#8E6819', stroke_width=3))
        inner.append(T(bx + 165, by + 44, lab, 34, O if i == 0 else Q['cream'], weight='bold', anchor='middle'))
    return body + R(0, 0, 1920, 1080, '#000000', opacity='.35') + plate(x0, y0, w, h, ''.join(inner)), extra


def act2():
    body, extra = level(0)
    a = [R(560, 50, 800, 980, '#F3EDDC', rx=6), R(560, 50, 800, 980, '#000000', filter='url(#grain)', opacity='.18'),
         C(1250, 170, 62, 'none', stroke='#9B6B3A', stroke_width=7, opacity='.25'),
         T(960, 140, 'АКТ № 1', 66, INK, weight='bold', anchor='middle', letter_spacing='3'), T(960, 190, 'выполненных работ', 40, INK, anchor='middle'), Ln(620, 222, 1300, 222, INK, 2.5)]
    y = 290
    for k, v in (('Адрес', 'подъезд 1, квартира 1'), ('Работы', 'вода к прибору «ванна»'), ('Исполнитель', 'гофра самоходная «Лапидус»'),
                 ('Ходов', '21 при норме 18'), ('Горячая линия', 'не вызывалась'), ('Мастер', 'не вызывался')):
        a += [T(620, y, k + ':', 34, INK, weight='bold'), T(840, y, v, 40, '#1C3C9A', font=HAND), Ln(836, y + 12, 1300, y + 12, '#9AA4B8', 1.5)]
        y += 66
    a += [R(620, 700, 330, 150, 'none', rx=10, stroke=INK, stroke_width=3), T(785, 745, 'РАЗРЯД', 30, INK, weight='bold', anchor='middle', letter_spacing='4'),
          T(785, 830, '4-й', 84, '#C73E2E', font=HAND, anchor='middle'), T(620, 930, 'Исполнитель ____________', 30, INK),
          T(790, 922, 'Лапидус', 46, '#1C3C9A', font=HAND, transform='rotate(-6 840 915)'), T(620, 985, 'Жилец ________________', 30, INK)]
    sx, sy, r = 1150, 845, 118
    st = (C(sx, sy, r, 'none', stroke='#2B56B8', stroke_width=8) + C(sx, sy, r - 30, 'none', stroke='#2B56B8', stroke_width=3)
          + '<text font-family="PT Sans Narrow" font-size="25" font-weight="bold" fill="#2B56B8" letter-spacing="2"><textPath href="#ring" xlink:href="#ring">ЖЭУ № 3 · АВАРИЙНО-ДИСПЕТЧЕРСКАЯ СЛУЖБА ·</textPath></text>'
          + T(sx, sy + 12, 'ВЫПОЛНЕНО', 34, '#2B56B8', weight='bold', anchor='middle'))
    a.append(G(st, transform='rotate(-14 %d %d)' % (sx, sy), opacity='.86'))
    over = R(0, 0, 1920, 1080, '#000000', opacity='.62') + G(''.join(a), filter='url(#dsh)', transform='rotate(-1.2 960 540)')
    for i, lab in enumerate(('Дальше ›', 'Ещё раз')):
        by = 820 + i * 110
        over += G(R(1440, by, 380, 84, 'url(#cylG)' if i == 0 else '#2A2622', rx=42, stroke=O if i == 0 else '#8E6819', stroke_width=4)
                  + T(1630, by + 56, lab, 42, O if i == 0 else Q['cream'], weight='bold', anchor='middle'), filter='url(#dsh)')
    return body + over, extra + '<path id="ring" d="M %d %d m -104 0 a 104 104 0 1 1 208 0 a 104 104 0 1 1 -208 0"/>' % (sx, sy)


def washed2():
    body, extra, (c, ox, oy) = frame(L[0], 9, 'head', no_lap=True)
    sw = []
    for y, row in enumerate(L[0]['grid']):
        for x, ch in enumerate(row):
            if ch == '~':
                dx, dy = ox + (x + .5) * c, oy + (y + .5) * c
                for k in range(4):
                    r = c * (.3 + k * .25)
                    sw.append(Pa(dd('M', dx - r, dy - c * .1, 'A', r, r * .38, 0, 0, 1, dx + r, dy - c * .1), stroke=Q['water'], stroke_width=c * .05, opacity='%.2f' % (.9 - k * .2), stroke_linecap='round'))
    band = R(0, 420, 1920, 210, 'rgba(12,14,16,0.84)') + T(960, 510, 'Лапидус ушёл в канализацию.', 68, Q['cream'], weight='bold', anchor='middle') + T(960, 585, 'Не навсегда. Отмена — Z.', 48, '#F6DB8A', anchor='middle')
    return body + ''.join(sw) + band, extra


# ---------------------------------------------------------------- меню и хрущёвка

def menu2(items=True):
    s = [R(0, 0, 1920, 1080, 'url(#bsm)'), R(0, 0, 1920, 1080, '#000000', filter='url(#grain)', opacity='.6')]
    for row in range(13):
        for col in range(15):
            s.append(R(col * 150 + (75 if row % 2 else 0) - 60, 280 + row * 64, 146, 60, 'none', stroke='#000000', stroke_width=2, opacity='.22'))
    s.append(Pg([(960, 60), (470, 1080), (1450, 1080)], 'url(#bulb)'))
    s.append(G(R(-10, 136, 1940, 58, 'url(#ironH)', stroke=O, stroke_width=5) + R(-10, 224, 1940, 36, 'url(#ironH)', stroke=O, stroke_width=4)
               + ''.join(R(xk, 128, 30, 74, 'url(#ironH)', rx=6, stroke=O, stroke_width=4) for xk in (260, 720, 1180, 1640)), filter='url(#dsh)'))
    s.append(Ln(960, 0, 960, 62, '#1A1A1A', 4) + C(960, 90, 30, '#FFF3C4', stroke=O, stroke_width=4) + C(951, 81, 9, '#FFFFFF', opacity='.9'))
    s.append(G(R(330, 258, 96, 840, 'url(#ironV)', stroke=O, stroke_width=5) + R(312, 330, 132, 40, 'url(#ironH)', rx=10, stroke=O, stroke_width=4)
               + R(312, 1010, 132, 40, 'url(#ironH)', rx=10, stroke=O, stroke_width=4), filter='url(#dsh)'))
    wx, wy, wr = 378, 640, 160
    wheel = [C(wx, wy, wr, 'none', stroke=O, stroke_width=52), C(wx, wy, wr, 'none', stroke=Q['red'], stroke_width=36),
             Pa(dd('M', wx - wr * .9, wy - wr * .35, 'A', wr, wr, 0, 0, 1, wx - wr * .2, wy - wr * .98), stroke='#F59A83', stroke_width=10, stroke_linecap='round')]
    for k in range(6):
        a = math.pi / 3 * k + .26
        wheel += [Ln(wx, wy, wx + math.cos(a) * wr, wy + math.sin(a) * wr, O, 32), Ln(wx, wy, wx + math.cos(a) * wr, wy + math.sin(a) * wr, Q['red'], 20)]
    wheel.append(C(wx, wy, 44, 'url(#cylG)', stroke=O, stroke_width=5))
    s.append(G(''.join(wheel), filter='url(#dsh)'))
    s.append(Ln(520, 520, 600, 626, '#8A8A8A', 3))
    s.append(G(R(560, 620, 260, 104, '#E9DFB8', rx=8, stroke=O, stroke_width=3) + T(690, 664, 'ГЛАВНЫЙ', 34, O, weight='bold', anchor='middle')
               + T(690, 704, 'ВЕНТИЛЬ ДОМА', 32, O, weight='bold', anchor='middle'), filter='url(#dsh)', transform='rotate(6 690 672)'))
    s.append(hero([(472, 990), (612, 990), (612, 850), (752, 850)], 140, 2, 5, active='head', ring=False))
    s.append(gen.logo(522, 300, 1.12))
    s.append(T(960, 548, 'НИ КАПЛИ', 76, Q['cream'], weight='bold', anchor='middle', letter_spacing='14', stroke=O, stroke_width=3, paint_order='stroke'))
    for i, it in enumerate(['Продолжить', 'Квартиры', 'Паспорт изделия', 'Настройки', 'Выход'] if items else []):
        by, sel = 606 + i * 90, i == 0
        s.append(G(R(1180, by, 540, 74, 'url(#cylG)' if sel else '#2A2622', rx=14, stroke=O if sel else '#8E6819', stroke_width=4)
                   + C(1200, by + 37, 7, '#C9CFD6', stroke=O, stroke_width=2) + C(1700, by + 37, 7, '#C9CFD6', stroke=O, stroke_width=2)
                   + T(1450, by + 52, it, 46, O if sel else Q['cream'], weight='bold', anchor='middle'), filter='url(#dsh)'))
    return ''.join(s), BASE


def select2(solved=(1,), opened=(2, 3)):
    rnd = random.Random(3)
    s = [R(0, 0, 1920, 1080, 'url(#sky)')]
    s += [C(rnd.uniform(0, 1920), rnd.uniform(10, 330), rnd.uniform(1, 2.4), '#FFFFFF', opacity='%.2f' % rnd.uniform(.3, .8)) for _ in range(70)]
    for bx, bw, bh in ((-20, 300, 420), (250, 230, 330), (1400, 250, 380), (1630, 320, 470)):
        s.append(R(bx, 940 - bh, bw, bh, '#243146'))
        for wy_ in range(int(940 - bh + 30), 910, 46):
            for wx_ in range(int(bx + 20), int(bx + bw - 30), 44):
                if rnd.random() < .22:
                    s.append(R(wx_, wy_, 22, 26, '#F2C66A', opacity='.75'))
    s.append(R(0, 940, 1920, 140, '#26241F'))
    bx0, bx1, top, rx = 560, 1360, 190, 950
    b = [R(bx0 - 24, top - 36, bx1 - bx0 + 48, 44, '#5E6468', stroke=O, stroke_width=5), R(bx0, top, bx1 - bx0, 940 - top, '#AEB4B7', stroke=O, stroke_width=6),
         Ln(bx0 + 130, top - 36, bx0 + 130, top - 150, O, 6), Ln(bx0 + 100, top - 120, bx0 + 160, top - 120, O, 5), Ln(bx0 + 110, top - 95, bx0 + 150, top - 95, O, 5)]
    b += [Ln(bx0, top + k * 150, bx1, top + k * 150, '#80878B', 4) for k in range(1, 5)]
    b += [R(bx0, 940, bx1 - bx0, 120, '#3B3632', stroke=O, stroke_width=5), T(bx0 + 30, 1012, 'подвал · главный вентиль', 30, '#C9C0AE'),
          R(rx, top - 10, 20, 1060 - top, 'url(#ironV)', stroke=O, stroke_width=3), R(rx + 4, 940 - ((max(solved) + 1) // 2 if solved else 0) * 150, 12, 120 + ((max(solved) + 1) // 2 if solved else 0) * 150, Q['water'])]
    # окна: прибор и плитка по файлам уровней (levels/NN.lua → L), чтобы новая квартира появлялась на доме сама
    FXF = {'bath': bath2, 'toilet': toilet2, 'sink': sink2, 'washer': gen2.washer2, 'dryer': gen2.dryer2, 'heater': gen2.heater2}
    fx = {}
    for lv in L:
        what = next((ob.get('what') for ob in lv['objects'] if ob['kind'] == 'fixture'), None)
        if what in FXF:
            fx[lv['id']] = (FXF[what], lv.get('tile') or 'mint')
    for apt in range(1, 11):
        fl, left = (apt + 1) // 2, apt % 2 == 1
        y0, x0, w, h = 940 - fl * 150 + 10, (bx0 + 20 if left else rx + 40), 350, 130
        if apt in solved:
            b.append(R(x0, y0, w, h, 'url(#warm)', stroke=O, stroke_width=4))
        elif apt in opened:
            b.append(R(x0, y0, w, h, '#33414F', stroke='#C99A2E', stroke_width=7))
        else:
            b.append(R(x0, y0, w, h, '#1B2026', stroke=O, stroke_width=4))
            for k in (-1, 1):
                b.append(R(x0 + 30, y0 + 50 + k * 22, w - 60, 22, '#6B4A2E', rx=4, stroke=O, stroke_width=2,
                           transform='rotate(%d %s %s)' % (k * 4, n(x0 + w / 2), n(y0 + 61 + k * 22))))
        if apt in fx:
            fn, tl = fx[apt]
            b.append(R(x0 + 4, y0 + 88, w - 8, 38, TILE[tl][0], opacity='.9' if apt in solved else '.35'))
            b.append(fn(x0 + w - 90, y0 + 66, 96, apt in solved))
            if apt == 1:
                b.append(headL((x0 + 150, y0 + 70), 'right', 70, True, False))
                b.append(R(x0 + 190, y0 + 16, 92, 34, 'rgba(255,255,255,0.8)', rx=8, stroke=O, stroke_width=2) + T(x0 + 236, y0 + 41, 'акт', 24, INK, weight='bold', anchor='middle'))
        b.append(R(x0 + 12, y0 + 12, 64, 46, '#1F4E97', rx=8, stroke=O, stroke_width=2) + T(x0 + 44, y0 + 46, str(apt), 32, '#FFFFFF', weight='bold', anchor='middle'))
    s.append(G(''.join(b), filter='url(#dsh)'))
    s.append(plate(40, 50, 440, 150, T(70, 122, 'ПОДЪЕЗД 1', 60, Q['cream'], weight='bold', letter_spacing='4') + T(70, 170, 'выберите квартиру', 34, '#C9D3DC')))
    leg = ''
    for i, (sw, txt) in enumerate((('url(#warm)', 'горит — акт подписан'), ('#33414F', 'рамка — можно брать'), ('#1B2026', 'доски — пока закрыто'))):
        leg += R(1440, 330 + i * 80, 64, 46, sw, stroke='#C99A2E' if i == 1 else O, stroke_width=4) + T(1524, 364 + i * 80, txt, 32, Q['cream'])
    leg += T(1440, 604, 'открыты две нерешённые', 30, '#C9D3DC') + T(1440, 640, 'квартиры сразу', 30, '#C9D3DC')
    s.append(plate(1410, 290, 480, 380, leg))
    return ''.join(s), BASE


# ---------------------------------------------------------------- паспорт изделия

def pan_moves(px, py):
    cc, s = 56, []
    for yy, m, lab in ((py + 152, 4, '+1  растянуться'), (py + 286, 2, '−1  сжаться')):
        s.append(hero([(px + 70 + i * cc, yy) for i in range(3)], cc, 2, 5, ring=False))
        s.append(gen.arrow(px + 250, yy, px + 300, yy))
        s.append(hero([(px + 340 + i * cc, yy) for i in range(m)], cc, 2, 5, ring=False))
        s.append(T(px + 340, yy - 46, lab, 26, INK, weight='bold'))
    return ''.join(s)


def pan_thread(px, py):
    cc, s = 64, []
    for i, (a, b, ok) in enumerate((('N', 'V', True), ('N', 'N', False), ('V', 'V', False))):
        y, x = py + 128 + i * 80, px + 230
        s.append(R(x - .5 * cc, y - .2 * cc, .52 * cc, .4 * cc, 'url(#ironH)', stroke=O, stroke_width=2))
        s.append(R(x + 1.15 * cc - .02 * cc, y - .2 * cc, .52 * cc, .4 * cc, 'url(#ironH)', stroke=O, stroke_width=2))
        s.append(port2(x, y, cc, 'right', a) + port2(x + 1.15 * cc, y, cc, 'left', b))
        s.append(T(px + 40, y + 12, {'N': 'Н', 'V': 'В'}[a] + ' + ' + {'N': 'Н', 'V': 'В'}[b], 34, INK, weight='bold'))
        s.append(gen.mark(px + 470, y, ok))
    return ''.join(s)


def pan_support(px, py):
    cc, s = 58, []
    s.append(R(px + 30, py + 250, 70, 70, 'url(#tpM)', rx=14, stroke=O, stroke_width=4) + R(px + 230, py + 250, 70, 70, 'url(#tpM)', rx=14, stroke=O, stroke_width=4))
    s.append(hero([(px + 108, py + 172), (px + 166, py + 172), (px + 224, py + 172)], cc, 2, 5, ring=False))
    s.append(gen.arrow(px + 166, py + 210, px + 166, py + 300, '#C0392B') + gen.mark(px + 60, py + 112, False, .8))
    s.append(R(px + 330, py + 72, 150, 26, 'url(#tpM)', rx=8, stroke=O, stroke_width=3))
    s.append(stub2(px + 405, py + 128, cc, 'down', 'V', 'up'))
    s.append(hero([(px + 405, py + 186), (px + 405, py + 244), (px + 405, py + 302)], cc, 2, 5, ring=False, screwed=(True, False)))
    s.append(gen.mark(px + 490, py + 200, True, .8))
    return ''.join(s)


def pan_drain(px, py):
    cc, s = 70, []
    s.append(R(px + 90, py + 255, 150, 64, 'url(#tpM)', rx=12, stroke=O, stroke_width=4) + R(px + 310, py + 255, 150, 64, 'url(#tpM)', rx=12, stroke=O, stroke_width=4))
    s.append(drain2(px + 275, py + 290, 70, bottom=py + 330))
    s.append(hero([(px + 275, py + 118), (px + 275, py + 188)], cc, 2, 5, ring=False))
    s.append(gen.arrow(px + 340, py + 130, px + 340, py + 225, '#C0392B') + T(px + 372, py + 196, '«смыло»', 40, INK, font=HAND) + gen.mark(px + 120, py + 150, False, .9))
    return ''.join(s)


def pan_soap(px, py):
    cc, s = 64, []
    y1, y2 = py + 150, py + 280
    s.append(hero([(px + 250, y1), (px + 186, y1), (px + 122, y1)], cc, 2, 5, active='heel', ring=False))
    s.append(porcelain2(px + 318, y1, cc) + gen.arrow(px + 362, y1, px + 420, y1) + gen.mark(px + 474, y1, True, .8))
    s.append(hero([(px + 122, y2), (px + 186, y2), (px + 250, y2)], cc, 2, 5, ring=False))
    s.append(porcelain2(px + 318, y2, cc) + gen.mark(px + 474, y2, False, .8))
    s += [C(px + bx, y2 + by, br, '#FFFFFF', stroke=O, stroke_width=2) for bx, by, br in ((290, -34, 9), (300, -16, 6), (282, 6, 7))]
    s.append(T(px + 30, y1 - 44, 'ноги', 28, INK, weight='bold') + T(px + 30, y2 - 44, 'голова', 28, INK, weight='bold'))
    return ''.join(s)


def pan_goal(px, py):
    cc, s, y = 64, [], py + 210
    s.append(source2(px + 64, y, cc, {'right': 'V'}, py + 110, py + 300))
    s.append(hero([(px + 128, y), (px + 192, y), (px + 256, y), (px + 320, y)], cc, 2, 5, ring=False, wet=True, screwed=(True, True)))
    s.append(bath2(px + 384, y, cc, True) + port2(px + 384, y - .02 * cc, cc, 'left', 'N', True))
    s.append(gen.mark(px + 486, py + 110, True) + T(px + 30, py + 330, 'стояк → Лапидус → прибор, ни капли мимо', 26, INK))
    return ''.join(s)


def pan_crane(px, py):
    """Кв. 6: голова поднимает деталь снизу; лежащее на Лапидусе с ним не едет и падает там, где он его оставил."""
    cc, s = 46, []
    nip = {'up': 'N', 'down': 'N'}
    fl = py + 312
    s.append(R(px + 24, fl, 236, 22, 'url(#tpY)', rx=6, stroke=O, stroke_width=3) + R(px + 286, fl, 236, 22, 'url(#tpY)', rx=6, stroke=O, stroke_width=3))
    # слева: голова снизу толкает деталь вверх
    s.append(hero([(px + 70, fl - 23), (px + 70, fl - 69)], cc, 2, 5, ring=False))
    s.append(fitting2(px + 70, fl - 115, cc, nip))
    s.append(gen.arrow(px + 104, fl - 69, px + 156, fl - 69))
    s.append(hero([(px + 200, fl - 23), (px + 200, fl - 69), (px + 200, fl - 115)], cc, 2, 5, ring=False))
    s.append(fitting2(px + 200, fl - 161, cc, nip))
    s.append(gen.arrow(px + 240, fl - 130, px + 240, fl - 188, '#2F8F4E') + gen.mark(px + 236, fl - 228, True, .7))
    # справа: деталь на спине остаётся, Лапидус уезжает — деталь падает на месте
    y1 = fl - 170
    s.append(hero([(px + 318, y1), (px + 364, y1), (px + 410, y1)], cc, 2, 5, ring=False))
    s.append(fitting2(px + 364, y1 - 46, cc, nip))
    s.append(gen.arrow(px + 330, y1 + 44, px + 330, fl - 58, '#8A8578', 4))
    s.append(hero([(px + 410, fl - 23), (px + 456, fl - 23), (px + 502, fl - 23)], cc, 2, 5, ring=False))
    s.append(fitting2(px + 364, fl - 23, cc, nip))
    s.append(Ln(px + 364, y1 - 18, px + 364, fl - 52, '#C0392B', 4, stroke_dasharray='10 8') + gen.arrow(px + 364, fl - 80, px + 364, fl - 50, '#C0392B', 5))
    return ''.join(s)


def card(num, title, pan, h=356):
    """Вкладыш нового правила на экране заявки (и страница паспорта): номер квартиры, где правило вводится, заголовок, немая панель.
    h — высота панели (card07 выше: две полосы)."""
    px, py = 10, 10
    s = [G(R(px, py, 540, h, '#FBF8F0', rx=10, stroke=INK, stroke_width=2.5) + C(px + 38, py + 40, 24, INK)
           + T(px + 38, py + 51, str(num), 30, '#FBF8F0', weight='bold', anchor='middle') + T(px + 76, py + 52, title, 32, INK, weight='bold'), filter='url(#dsh)'),
         pan(px, py)]
    return ''.join(s), BASE


def card6():
    return card(10, 'Поднимает, но не носит', pan_crane)


def jet2(x1, y1, x2, y2, c):
    """Струя на карточке: вода вдоль оси, блик и пенная шапка на конце."""
    a = math.atan2(y2 - y1, x2 - x1)
    px, py = -math.sin(a), math.cos(a)
    s = [Ln(x1, y1, x2, y2, O, c * .34), Ln(x1, y1, x2, y2, Q['water'], c * .26),
         Ln(x1 + px * c * .05, y1 + py * c * .05, x2 + px * c * .05, y2 + py * c * .05, '#FFFFFF', c * .05, opacity='.55')]
    for k in range(5):
        t = k / 5 * math.pi * 2
        s.append(C(x2 + math.cos(t) * c * .10, y2 + math.sin(t) * c * .07, c * .10, '#FFFFFF', stroke=O, stroke_width=1.5))
    for k in range(5):
        t = k / 5 * math.pi * 2
        s.append(C(x2 + math.cos(t) * c * .10, y2 + math.sin(t) * c * .07, c * .085, '#FFFFFF'))
    return ''.join(s)


def pan_pressure(px, py):
    """Кв. 7: манометр — длина струи; струя вверх держит (лифт); струя толкает; резьба сильнее струи."""
    cc, s = 42, []
    fl = py + 312
    for x0, w in ((px + 24, 146), (px + 196, 150), (px + 372, 146)):
        s.append(R(x0, fl, w, 22, 'url(#tpM)', rx=6, stroke=O, stroke_width=3))
    for x0 in (px + 183, px + 359):
        s.append(Ln(x0, py + 92, x0, fl - 8, '#B9AF98', 2.5, stroke_dasharray='6 8'))
    # 1) стояк с манометром (напор 2): столб в две клетки, деталь стоит над верхушкой — лифт
    sx, sy = px + 70, fl - .5 * cc
    s.append(source2(sx, sy, cc, {'up': 'N'}, sy - .5 * cc, fl + 20, 2))
    s.append(jet2(sx, sy - .45 * cc, sx, sy - 2.45 * cc, cc))
    s.append(fitting2(sx, sy - 3 * cc, cc, {'up': 'N', 'down': 'N'}))
    s.append(gen.arrow(sx - 44, sy - 1.3 * cc, sx - 44, sy - 3.2 * cc, '#2F8F4E', 5))
    # 2) струя вбок толкает деталь до своего конца
    bx, by = px + 216, fl - 2.5 * cc
    s.append(source2(bx, by, cc, {'right': 'N'}, by - .5 * cc, fl + 20, 2))
    s.append(jet2(bx + .45 * cc, by, bx + 2.3 * cc, by, cc))
    s.append(fitting2(bx + 2.9 * cc, by, cc, {'left': 'V', 'right': 'V'}))
    s.append(gen.arrow(bx + 2.5 * cc, by - .85 * cc, bx + 3.5 * cc, by - .85 * cc, INK, 5))
    # 3) резьба сильнее струи: деталь, вошедшая в первую клетку струи, прикручивается и глушит течь
    tx, ty = px + 470, fl - .5 * cc
    s.append(source2(tx, ty, cc, {'up': 'N'}, ty - .5 * cc, fl + 20, 0))
    s.append(fitting2(tx, ty - cc, cc, {'down': 'V'}))
    s.append(R(tx - 2.75 * cc, ty - .5 * cc, 2.2 * cc, 16, 'url(#tpM)', rx=5, stroke=O, stroke_width=3))
    s.append(hero([(tx - 2.2 * cc, ty - cc), (tx - 1.1 * cc, ty - cc)], cc, 2, 5, ring=False))
    s.append(gen.arrow(tx - 1.2 * cc, ty - 2.1 * cc, tx - .35 * cc, ty - 2.1 * cc, INK, 5))
    s.append(Ln(tx, ty - 1.55 * cc, tx, ty - 3.3 * cc, Q['water'], cc * .22, opacity='.35', stroke_dasharray='8 7'))
    s.append(gen.mark(tx, ty - 2.45 * cc, False, .55))
    s.append(gen.mark(tx + 34, ty - 1.9 * cc, True, .6))
    return ''.join(s)


def pan_lapjet(px, py):
    """Нижняя полоса card07 «Лапидус в струе»: столб поднимает неприкрученного целиком, но потолок над любой клеткой тела
    останавливает подъём; деталь под телом в столбе стоит; прикрученный Лапидус обрывает струю."""
    cc, s = 34, []
    fl, top = py + 204, py + 54
    s.append(Ln(px + 24, py + 6, px + 516, py + 6, '#B9AF98', 2.5, stroke_dasharray='6 8'))
    s.append(T(px + 30, py + 36, 'Лапидус в струе', 26, INK, weight='bold'))
    for x0, w in ((px + 24, 150), (px + 200, 150), (px + 376, 140)):
        s.append(R(x0, fl, w, 18, 'url(#tpM)', rx=6, stroke=O, stroke_width=3))
    for x0 in (px + 187, px + 363):
        s.append(Ln(x0, py + 46, x0, fl - 6, '#B9AF98', 2.5, stroke_dasharray='6 8'))
    # 1) столб поднимает целиком — но под потолком стоит
    sx, sy = px + 70, fl - .5 * cc
    s.append(source2(sx, sy, cc, {'up': 'N'}, sy - .5 * cc, fl + 16, 3))
    s.append(jet2(sx, sy - .45 * cc, sx, sy - 2.35 * cc, cc))
    s.append(R(px + 30, top, 120, 12, 'url(#tpM)', rx=5, stroke=O, stroke_width=3))
    s.append(hero([(sx - cc, sy - 3.0 * cc), (sx, sy - 3.0 * cc), (sx + cc, sy - 3.0 * cc)], cc, 2, 5, ring=False))
    s.append(gen.arrow(sx + 2.3 * cc, sy - .9 * cc, sx + 2.3 * cc, sy - 2.2 * cc, '#2F8F4E', 4))
    s.append(gen.mark(sx + 2.3 * cc, sy - 2.8 * cc, True, .5))
    # 2) деталь под телом в столбе стоит
    bx, by = px + 262, fl - .5 * cc
    s.append(source2(bx, by, cc, {'up': 'N'}, by - .5 * cc, fl + 16, 3))
    s.append(jet2(bx, by - .45 * cc, bx, by - 1.35 * cc, cc))
    s.append(fitting2(bx, by - 1.9 * cc, cc, {'up': 'N', 'down': 'N'}))
    s.append(R(px + 206, top, 120, 12, 'url(#tpM)', rx=5, stroke=O, stroke_width=3))
    s.append(hero([(bx - cc, by - 3.0 * cc), (bx, by - 3.0 * cc), (bx + cc, by - 3.0 * cc)], cc, 2, 5, ring=False))
    s.append(Ln(bx + 2.1 * cc, by - 1.4 * cc, bx + 2.1 * cc, by - 2.3 * cc, '#8A8578', 3, stroke_dasharray='6 5'))
    s.append(gen.mark(bx + 2.1 * cc, by - 2.8 * cc, True, .5))
    # 3) прикрученный Лапидус обрывает струю
    tx, ty = px + 420, fl - .5 * cc
    s.append(source2(tx, ty, cc, {'up': 'N'}, ty - .5 * cc, fl + 16, 3))
    s.append(hero([(tx, ty - 1.05 * cc), (tx, ty - 2.05 * cc), (tx + cc, ty - 2.05 * cc)], cc, 2, 5, ring=False, screwed=(True, False), wet=True))
    s.append(Ln(tx, ty - .6 * cc, tx, ty - 3.6 * cc, Q['water'], cc * .22, opacity='.25', stroke_dasharray='8 7'))
    s.append(gen.mark(tx + 2.1 * cc, ty - 1.4 * cc, False, .5))
    return ''.join(s)


def card7():
    return card(6, 'Струя толкает и держит', lambda px, py: pan_pressure(px, py) + pan_lapjet(px, py + 336), h=560)


def drops(x, y, k=1.0):
    return ''.join(E(x + dx * k, y + dy * k, 6 * k, 9 * k, Q['water'], stroke=O, stroke_width=1.5) for dx, dy in ((0, 0), (8, 26), (-6, 50)))


def pan_intro(px, py):
    """Кв. 1: Н входит в В (Н+Н и В+В — нет); цель — вода от стояка через Лапидуса до прибора."""
    cc, s = 60, []
    y = py + 118
    for x, a, b, ok in ((px + 70, 'N', 'V', True), (px + 300, 'N', 'N', False)):
        s.append(R(x - .5 * cc, y - .2 * cc, .52 * cc, .4 * cc, 'url(#ironH)', stroke=O, stroke_width=2))
        s.append(R(x + 1.13 * cc, y - .2 * cc, .52 * cc, .4 * cc, 'url(#ironH)', stroke=O, stroke_width=2))
        s.append(port2(x, y, cc, 'right', a) + port2(x + 1.15 * cc, y, cc, 'left', b))
        s.append(T(x + .57 * cc, y + 62, {'N': 'Н', 'V': 'В'}[a] + ' + ' + {'N': 'Н', 'V': 'В'}[b], 30, INK, weight='bold', anchor='middle'))
        s.append(gen.mark(x + 150, y, ok, .8))
    cc, y = 56, py + 268
    s.append(source2(px + 60, y, cc, {'right': 'V'}, py + 205, py + 340))
    s.append(hero([(px + 116 + i * cc, y) for i in range(4)], cc, 2, 5, ring=False, wet=True, screwed=(True, True)))
    s.append(bath2(px + 116 + 4 * cc, y, cc, True) + port2(px + 116 + 4 * cc, y - .02 * cc, cc, 'left', 'N', True))
    s.append(gen.mark(px + 490, y - 50, True, .9))
    return ''.join(s)


def pan_parts(px, py):
    """Кв. 4: деталь падает и свинчивается с той, на которую упала; прикрученная к сети — «каменеет» (сталь)."""
    cc, s = 58, []
    fl = py + 312
    s.append(R(px + 24, fl, 236, 22, 'url(#tpB)', rx=6, stroke=O, stroke_width=3) + R(px + 286, fl, 236, 22, 'url(#tpB)', rx=6, stroke=O, stroke_width=3))
    s.append(Ln(px + 273, py + 92, px + 273, fl - 8, '#B9AF98', 2.5, stroke_dasharray='6 8'))
    # слева: латунная деталь падает на другую и свинчивается
    x = px + 140
    s.append(fitting2(x, fl - .5 * cc, cc, {'up': 'V', 'down': 'V'}))
    s.append(fitting2(x, fl - 2.9 * cc, cc, {'up': 'N', 'down': 'N'}))
    s.append(gen.arrow(x + 58, fl - 3.2 * cc, x + 58, fl - 1.6 * cc, '#C0392B', 5))
    s.append(gen.mark(x + 80, py + 100, True, .7))
    # справа: деталь прикрутилась к сети — стала сталью, её больше не сдвинуть
    x, y = px + 440, fl - 2.2 * cc
    s.append(stub2(x - cc, y, cc, 'right', 'V', 'left'))
    s.append(G(fitting2(x, y, cc, {'left': 'N', 'right': 'N'}), filter='url(#steel)'))
    s.append(fluff2(x - .5 * cc, y, cc))
    s.append(T(x - 20, fl - 30, 'намертво', 34, INK, font=HAND, anchor='middle'))
    return ''.join(s)


def pan_tee(px, py):
    """Кв. 5: у тройника три выхода; лишний течёт — вода не дойдёт; заглушка на лишнем — дойдёт."""
    cc, s = 60, []
    for i, (y, plugged) in enumerate(((py + 150, False), (py + 285, True))):
        x = px + 120
        s.append(source2(x - cc, y, cc, {'right': 'V'}, y - .5 * cc, y + .6 * cc))
        s.append(fitting2(x, y, cc, {'left': 'N', 'right': 'V', 'up': 'V'}))
        s.append(bath2(x + 4 * cc, y, cc, plugged) + port2(x + 4 * cc, y - .02 * cc, cc, 'left', 'N', True))
        if plugged:
            s.append(fitting2(x, y - cc, cc, {'down': 'N'}))
            s.append(Ln(x + .6 * cc, y, x + 3.4 * cc, y, Q['water'], 14, opacity='.9'))
            s.append(gen.mark(px + 490, y - 40, True, .8))
        else:
            s.append(drops(x, y - .75 * cc) + drops(x + 18, y - .9 * cc, .8))
            s.append(gen.mark(px + 490, y - 40, False, .8))
    return ''.join(s)


def card1():
    return card(1, 'Н входит в В — вода до прибора', pan_intro)


def card3():
    return card(4, 'Фаянс толкают только ноги', pan_soap)


def card4():
    return card(5, 'Деталь падает и свинчивается', pan_parts)


def card5():
    return card(3, 'Лишний выход — заглушить', pan_tee)


def card_fall():
    return card(1, 'Без опоры падает, резьба держит', pan_support)


def card_drain():
    return card(1, 'Слив смывает', pan_drain)


def pan_hose(px, py):
    """Кв. 8 «Брандспойт»: конец Лапидуса, прикрученного к мокрому крану, сам бьёт струёй туда, куда смотрит;
    своя струя его не толкает; струя сбивает деталь с полки прочь от крана."""
    cc, s = 40, []
    fl = py + 312
    for x0, w in ((px + 24, 236), (px + 286, 236)):
        s.append(R(x0, fl, w, 22, 'url(#tpB)', rx=6, stroke=O, stroke_width=3))
    s.append(Ln(px + 273, py + 92, px + 273, fl - 8, '#B9AF98', 2.5, stroke_dasharray='6 8'))

    def tap(x, y):  # мокрый кран в стене: стальной отвод с резьбой В и капелькой воды
        return (R(x - 14, y - .9 * cc, 20, 1.8 * cc, 'url(#ironV)', stroke=O, stroke_width=3)
                + stub2(x + .3 * cc, y, cc, 'right', 'V', 'left')
                + Ln(x + .55 * cc, y, x + .62 * cc, y, Q['water'], cc * .16, opacity='.9'))
    # слева: ноги прикручены к крану, из головы бьёт струя; сам Лапидус на месте
    sx, sy = px + 40, fl - 1.4 * cc
    s.append(T(px + 30, py + 118, 'прикручен к мокрому —', 24, INK, weight='bold') + T(px + 30, py + 146, 'конец сам бьёт струёй', 24, INK, weight='bold'))
    s.append(tap(sx, sy))
    s.append(hero([(sx + 1.3 * cc, sy), (sx + 2.3 * cc, sy), (sx + 3.3 * cc, sy)], cc, 2, 5, ring=False, wet=True, screwed=(True, False)))
    s.append(jet2(sx + 3.8 * cc, sy, sx + 5.2 * cc, sy, cc))
    s.append(gen.mark(px + 232, sy - 1.3 * cc, True, .6))
    # справа: струя сбивает пробку с полки прочь от крана; своя струя Лапидуса не толкает (серая стрелка назад зачёркнута)
    bx, by = px + 302, fl - 1.4 * cc
    s.append(T(px + 292, py + 118, 'струя сбивает деталь,', 24, INK, weight='bold') + T(px + 292, py + 146, 'а самого не толкает', 24, INK, weight='bold'))
    s.append(tap(bx, by))
    s.append(hero([(bx + 1.3 * cc, by), (bx + 2.3 * cc, by)], cc, 2, 5, ring=False, wet=True, screwed=(True, False)))
    s.append(jet2(bx + 2.8 * cc, by, bx + 3.8 * cc, by, cc))
    s.append(R(bx + 3.6 * cc, by + .5 * cc, 2.0 * cc, 14, 'url(#tpB)', rx=5, stroke=O, stroke_width=3))
    s.append(fitting2(bx + 4.3 * cc, by, cc, {'left': 'N'}))
    s.append(gen.arrow(bx + 4.5 * cc, by - 1.0 * cc, bx + 5.4 * cc, by - 1.0 * cc, INK, 5))
    s.append(gen.arrow(bx + 2.2 * cc, by - 1.1 * cc, bx + 1.3 * cc, by - 1.1 * cc, '#8A8578', 4) + gen.mark(bx + 1.75 * cc, by - 1.75 * cc, False, .5))
    return ''.join(s)


def pan_comb(px, py):
    """Кв. 9 «Гребёнка»: 1) мокрая гребёнка бьёт всеми открытыми выходами; 2) сухая резьба хватает деталь сразу и навсегда;
    3) деталь едет по гребням фонтанов — второй столб поднимает стопку."""
    cc, s = 36, []
    fl = py + 312
    for x0, w in ((px + 24, 150), (px + 196, 150), (px + 372, 146)):
        s.append(R(x0, fl, w, 18, 'url(#tpY)', rx=6, stroke=O, stroke_width=3))
    for x0 in (px + 183, px + 359):
        s.append(Ln(x0, py + 92, x0, fl - 8, '#B9AF98', 2.5, stroke_dasharray='6 8'))

    def comb(x, y, wet):
        body = (gen2.pipe2(x, y, cc, {'left': 'V', 'up': 'N', 'right': 'N'}) + gen2.pipe2(x + cc, y, cc, {'left': 'V', 'up': 'N', 'right': 'N'}))
        return body
    # 1) мокрая гребёнка: два фонтана вверх и струя вбок
    ax, ay = px + 60, fl - .5 * cc
    s.append(source2(ax - cc, ay, cc, {'right': 'V'}, ay - .5 * cc, fl + 16, 2))
    s.append(comb(ax, ay, True))
    s.append(jet2(ax, ay - .45 * cc, ax, ay - 2.2 * cc, cc) + jet2(ax + cc, ay - .45 * cc, ax + cc, ay - 2.2 * cc, cc))
    s.append(jet2(ax + 1.5 * cc, ay, ax + 3.0 * cc, ay, cc))
    s.append(T(px + 30, py + 118, 'намокла — бьёт', 22, INK, weight='bold') + T(px + 30, py + 144, 'всеми выходами', 22, INK, weight='bold'))
    # 2) сухая гребёнка хватает деталь сразу (пух, крестик)
    bx, by = px + 240, fl - .5 * cc
    s.append(comb(bx, by, False))
    s.append(G(fitting2(bx, by - cc, cc, {'down': 'V', 'left': 'V', 'right': 'V'}), filter='url(#steel)'))
    s.append(fluff2(bx, by - .5 * cc, cc))
    s.append(gen.mark(bx + 2.2 * cc, by - 1.6 * cc, False, .55))
    s.append(T(px + 206, py + 118, 'сухая — хватает', 22, INK, weight='bold') + T(px + 206, py + 144, 'сразу, навсегда', 22, INK, weight='bold'))
    # 3) стопка едет лифтом: заглушка в столбе, тройник на ней — вверх
    cx, cy = px + 400, fl - .5 * cc
    s.append(source2(cx - cc, cy, cc, {'right': 'V'}, cy - .5 * cc, fl + 16, 2))
    s.append(comb(cx, cy, True))
    s.append(jet2(cx + cc, cy - .45 * cc, cx + cc, cy - 1.3 * cc, cc))
    s.append(fitting2(cx + cc, cy - 1.8 * cc, cc, {'down': 'V'}))
    s.append(fitting2(cx + cc, cy - 2.8 * cc, cc, {'down': 'V', 'left': 'V', 'right': 'V'}))
    s.append(gen.arrow(cx + 2.4 * cc, cy - 1.6 * cc, cx + 2.4 * cc, cy - 3.2 * cc, '#2F8F4E', 4))
    s.append(T(px + 382, py + 118, 'стопка в столбе', 22, INK, weight='bold') + T(px + 382, py + 144, 'едет лифтом', 22, INK, weight='bold'))
    return ''.join(s)


def card9():
    return card(8, 'Гребёнка', pan_comb)


def card8():
    return card(7, 'Брандспойт', pan_hose)


CARDS = {'card01': card1, 'card01b': card_fall, 'card01c': card_drain, 'card03': card5, 'card04': card3, 'card05': card4,
         'card06': card7, 'card07': card8, 'card08': card9, 'card10': card6}  # ключ = номер квартиры после перестановки 02.10


def passport2():
    s = [R(0, 0, 1920, 1080, '#2A3035'), G(R(70, 40, 1780, 1000, '#F1ECDF', rx=10) + R(70, 40, 1780, 1000, '#000000', filter='url(#grain)', opacity='.12'), filter='url(#dsh)')]
    s += [T(130, 128, 'ПАСПОРТ ИЗДЕЛИЯ', 62, INK, weight='bold', letter_spacing='4'),
          T(130, 182, 'Гофра самоходная «Лапидус». Длина 2–5 клеток. Совместимость с фаянсом: ногами.', 34, INK),
          T(130, 224, 'Гарантия на героя не распространяется.', 34, INK)]
    for i, (title, fn) in enumerate((('Ход концом: тянется и сжимается', pan_moves), ('Н входит в В — лицом к лицу', pan_thread),
                                     ('Без опоры падает, резьба держит', pan_support), ('Слив смывает', pan_drain),
                                     ('Фаянс толкают только ноги', pan_soap), ('Цель: вода до прибора', pan_goal))):
        px, py = 130 + (i % 3) * 570, 262 + (i // 3) * 386
        s += [R(px, py, 540, 356, '#FBF8F0', rx=10, stroke=INK, stroke_width=2.5), C(px + 38, py + 40, 24, INK),
              T(px + 38, py + 51, str(i + 1), 30, '#FBF8F0', weight='bold', anchor='middle'), T(px + 76, py + 52, title, 32, INK, weight='bold'), fn(px, py)]
    return ''.join(s), BASE


# ---------------------------------------------------------------- немые сцены

def resident(x, y):
    """Жилец кв. 2: майка, треники с вытянутыми коленками, газета. x, y — таз."""
    s = []
    s.append(Pa(dd('M', x - 46, y, 'L', x - 58, y + 170, 'L', x - 14, y + 170, 'L', x - 2, y + 50, 'L', x + 10, y + 170, 'L', x + 54, y + 170, 'L', x + 46, y, 'Z'),
                '#3D5A8E', stroke=O, stroke_width=6, stroke_linejoin='round'))
    s += [E(x - 36, y + 92, 22, 26, '#4A69A2', stroke=O, stroke_width=4), E(x + 32, y + 92, 22, 26, '#4A69A2', stroke=O, stroke_width=4)]
    s.append(Pa(dd('M', x - 50, y + 4, 'Q', x - 58, y - 90, x - 36, y - 150, 'L', x + 36, y - 150, 'Q', x + 58, y - 90, x + 50, y + 4, 'Z'), '#F6F4EF', stroke=O, stroke_width=6))
    s.append(Pa(dd('M', x - 22, y - 150, 'Q', x, y - 118, x + 22, y - 150), stroke=O, stroke_width=5))
    for sx in (-1, 1):
        s.append(Pa(dd('M', x + sx * 44, y - 140, 'Q', x + sx * 78, y - 70, x + sx * 52, y - 10), stroke=O, stroke_width=26, stroke_linecap='round'))
        s.append(Pa(dd('M', x + sx * 44, y - 140, 'Q', x + sx * 78, y - 70, x + sx * 52, y - 10), stroke='#F0BD99', stroke_width=16, stroke_linecap='round'))
    s.append(R(x + 40, y - 70, 90, 110, '#E8E2CF', stroke=O, stroke_width=4, transform='rotate(12 %d %d)' % (x + 85, y - 15)))
    s += [Ln(x + 55, y - 45 + k * 18, x + 115, y - 33 + k * 18, '#9A9480', 3) for k in range(4)]
    s += [E(x, y - 196, 46, 52, 'url(#skinG)', stroke=O, stroke_width=5), E(x - 4, y - 172, 30, 20, '#4E6078', opacity='.22')]
    s.append(Pa(dd('M', x - 42, y - 214, 'Q', x - 30, y - 262, x + 4, y - 250, 'Q', x + 40, y - 262, x + 44, y - 214, 'Q', x + 20, y - 236, x - 42, y - 214, 'Z'), '#6B4B32', stroke=O, stroke_width=4))
    for sx in (-1, 1):
        s += [C(x + sx * 18, y - 200, 14, '#FFFFFF', stroke=O, stroke_width=4), C(x + sx * 18, y - 198, 5, O)]
    s += [Ln(x - 4, y - 200, x + 4, y - 200, O, 4), Pa(dd('M', x - 14, y - 170, 'Q', x, y - 176, x + 14, y - 170), stroke=O, stroke_width=4, stroke_linecap='round')]
    return ''.join(s)


def scenes2():
    s = [R(0, 0, 1920, 1080, '#171B1E'), T(960, 92, 'Немые сцены после победы · ключевые кадры', 48, Q['cream'], weight='bold', anchor='middle')]
    clips = ''
    titles = ('Кв. 1 · ванна наполнилась, селезень уплывает за кадр', 'Кв. 2 · три недели ждал воду: встал — и сел обратно', 'Кв. 3 · гора посуды: отмыта одна тарелка')
    for i in range(3):
        x0, y0, w, h = 60 + i * 610, 160, 580, 640
        clips += '<clipPath id="cp%d"><rect x="%d" y="%d" width="%d" height="%d" rx="16"/></clipPath>' % (i, x0, y0, w, h)
        cx, cy = x0 + w / 2, y0 + h / 2
        b = [R(x0, y0, w, h, 'url(#%s)' % ('tpM', 'tpB', 'tpY')[i]), R(x0, y0 + h - 80, w, 80, '#6B5B4B'), R(x0, y0, w, h, 'url(#vg2)')]
        if i == 0:
            b.append(G(bath2(cx - 60, cy + 120, 420, True), filter='url(#dsh)'))
            b.append(Pa(dd('M', cx - 300, cy + 40, 'q', -40, 90, -14, 220), stroke=Q['water'], stroke_width=18, stroke_linecap='round'))
            b.append(gen.duck(x0 + w - 30, cy - 20, 1.4))
            b += [Ln(x0 + w - 160 - k * 30, cy - 36 + k * 18, x0 + w - 122 - k * 30, cy - 36 + k * 18, '#FFFFFF', 6, opacity='.8') for k in range(3)]
        elif i == 1:
            b.append(G(R(cx + 150, cy - 250, 116, 136, '#FFFFFF', stroke=O, stroke_width=4) + T(cx + 208, cy - 166, '21', 58, '#C73E2E', weight='bold', anchor='middle')
                       + Ln(cx + 164, cy - 232, cx + 252, cy - 132, INK, 5) + Ln(cx + 252, cy - 232, cx + 164, cy - 132, INK, 5), filter='url(#dsh)'))
            b.append(G(toilet2(cx - 40, cy + 170, 330, False), filter='url(#dsh)'))
            b.append(G(resident(cx + 30, cy + 70), filter='url(#dsh)'))
            b.append(gen.arrow(cx + 170, cy + 40, cx + 170, cy - 60, Q['cream'], 9) + gen.arrow(cx + 214, cy - 60, cx + 214, cy + 40, Q['cream'], 9))
        else:
            b.append(G(sink2(cx - 20, cy + 190, 340, True), filter='url(#dsh)'))
            for k in range(9):
                b.append(E(cx - 80 + (k % 2) * 10, cy + 70 - k * 28, 110, 20, 'url(#enam)', stroke=O, stroke_width=4))
            b.append(G(E(cx + 170, cy - 60, 80, 80, 'url(#enam)', stroke=O, stroke_width=5) + E(cx + 170, cy - 60, 48, 48, 'none', stroke='#D5DBE3', stroke_width=4), filter='url(#dsh)'))
            for sx, sy, sr in ((230, -140, 18), (110, -120, 11), (230, 20, 12)):
                b.append(Pg([(cx + sx, cy + sy - sr), (cx + sx + sr * .3, cy + sy - sr * .3), (cx + sx + sr, cy + sy), (cx + sx + sr * .3, cy + sy + sr * .3),
                             (cx + sx, cy + sy + sr), (cx + sx - sr * .3, cy + sy + sr * .3), (cx + sx - sr, cy + sy), (cx + sx - sr * .3, cy + sy - sr * .3)], '#FFFFFF'))
        s.append(G(''.join(b), clip_path='url(#cp%d)' % i))
        s.append(R(x0, y0, w, h, 'none', rx=16, stroke='#C99A2E', stroke_width=4))
        s += [T(cx, y0 + h + 60 + k * 44, ln, 34, Q['cream'], anchor='middle') for k, ln in enumerate(wrap(titles[i], 30))]
    return ''.join(s), BASE + clips


def scenes45():
    """Немые сцены 4 и 5 (§10): те же панели 580×640, что в scenes2(), на местах 1 и 2."""
    s = [R(0, 0, 1920, 1080, '#171B1E')]
    clips = ''
    for i, (apt, pat) in enumerate(((4, 'tpM'), (5, 'tpB'))):
        x0, y0, w, h = 60 + i * 610, 160, 580, 640
        clips += '<clipPath id="cq%d"><rect x="%d" y="%d" width="%d" height="%d" rx="16"/></clipPath>' % (i, x0, y0, w, h)
        cx, cy = x0 + w / 2, y0 + h / 2
        fl = y0 + h - 80
        b = [R(x0, y0, w, h, 'url(#%s)' % pat), R(x0, fl, w, 80, '#6B5B4B'), R(x0, y0, w, h, 'url(#vg2)')]
        if apt == 4:
            # стиральная машина на отжиме уходит из кадра: половина уже за краем, шланг натянут струной
            mx, my = x0 + w - 40, fl - 150
            b.append(Pa(dd('M', x0 - 10, fl - 120, 'L', mx - 150, fl - 128), stroke=O, stroke_width=22, stroke_linecap='round'))
            b.append(Pa(dd('M', x0 - 10, fl - 120, 'L', mx - 150, fl - 128), stroke='#DCE2E8', stroke_width=13, stroke_linecap='round'))
            b += [Ln(mx - 330 + k * 14, fl - 250 + k * 64, mx - 190 + k * 10, fl - 250 + k * 64, '#FFFFFF', 7, opacity='.75') for k in range(4)]
            for k in range(2):
                b.append(Ln(x0 + 60, fl + 18 + k * 30, mx - 120, fl + 18 + k * 30, '#3A3129', 9, stroke_dasharray='34 22'))
            b.append(E(x0 + 150, fl + 4, 90, 16, 'url(#waterG)', stroke=O, stroke_width=3, opacity='.9'))
            b += [C(x0 + 120 + dx, fl - 30 + dy, r, Q['water'], stroke=O, stroke_width=2) for dx, dy, r in ((0, 0, 9), (40, -22, 7), (78, 4, 6))]
            b.append(G(gen2.washer2(mx, my, 330, True), transform='rotate(9 %s %s)' % (n(mx), n(my)), filter='url(#dsh)'))
            b += [Pa(dd('M', mx - 180, my - 150 + k * 90, 'q', -22, 14, 0, 28, 't', 0, 28), stroke='#FFFFFF', stroke_width=6, stroke_linecap='round', opacity='.8') for k in range(3)]
        else:
            # полотенцесушитель высушил один носок; от второго осталась пустая прищепка и облачко
            b.append(G(gen2.dryer2(cx - 40, cy - 10, 400, True, socks=1), filter='url(#dsh)'))
            px, py = cx + 60, cy + 110
            b.append(R(px - 10, py - 34, 20, 44, '#C49A5E', rx=5, stroke=O, stroke_width=4))
            b.append(Ln(px, py - 30, px, py + 6, '#7A5A34', 3))
            ghost = dd('M', px - 28, py + 14, 'L', px - 28, py + 120, 'Q', px - 28, py + 158, px + 20, py + 158, 'L', px + 58, py + 158,
                       'Q', px + 82, py + 158, px + 82, py + 132, 'Q', px + 82, py + 108, px + 44, py + 104, 'L', px + 28, py + 104, 'L', px + 28, py + 14, 'Z')
            b.append(Pa(ghost, 'none', stroke='#F4EEDC', stroke_width=5, stroke_dasharray='16 12', stroke_linejoin='round', opacity='.8'))
            for dx, dy, r in ((104, 40, 26), (132, 18, 20), (150, 52, 17), (118, 74, 14)):
                b.append(C(px + dx, py + dy, r, '#F4F7FA', stroke=O, stroke_width=3, opacity='.92'))
            for dx, dy, sr in ((170, -10, 14), (86, -40, 10), (178, 92, 9)):
                sx_, sy_ = px + dx, py + dy
                b.append(Pg([(sx_, sy_ - sr), (sx_ + sr * .3, sy_ - sr * .3), (sx_ + sr, sy_), (sx_ + sr * .3, sy_ + sr * .3),
                             (sx_, sy_ + sr), (sx_ - sr * .3, sy_ + sr * .3), (sx_ - sr, sy_), (sx_ - sr * .3, sy_ - sr * .3)], '#FFFFFF'))
        s.append(G(''.join(b), clip_path='url(#cq%d)' % i))
        s.append(R(x0, y0, w, h, 'none', rx=16, stroke='#C99A2E', stroke_width=4))
    return ''.join(s), BASE + clips


def ushanka(x, y, sc=1.0, tilt=0):
    """Шапка-ушанка: мех, отвороты, завязки. x, y — центр макушки головы."""
    f, fd, fl = '#6B4B32', '#4A3322', '#8E6A4C'
    u = []
    u.append(Pa(dd('M', x - 58 * sc, y + 18 * sc, 'Q', x - 62 * sc, y - 52 * sc, x, y - 58 * sc, 'Q', x + 62 * sc, y - 52 * sc, x + 58 * sc, y + 18 * sc, 'Z'),
                f, stroke=O, stroke_width=5, stroke_linejoin='round'))
    for k in range(7):
        a = math.pi * (0.15 + 0.7 * k / 6)
        u.append(Ln(x - math.cos(a) * 40 * sc, y - 12 * sc - math.sin(a) * 34 * sc, x - math.cos(a) * 52 * sc, y - 14 * sc - math.sin(a) * 44 * sc, fl, 4, opacity='.8'))
    for sx in (-1, 1):
        u.append(Pa(dd('M', x + sx * 46 * sc, y + 4 * sc, 'Q', x + sx * 72 * sc, y + 30 * sc, x + sx * 60 * sc, y + 84 * sc, 'Q', x + sx * 44 * sc, y + 92 * sc, x + sx * 36 * sc, y + 70 * sc,
                        'Q', x + sx * 34 * sc, y + 34 * sc, x + sx * 46 * sc, y + 4 * sc, 'Z'), fd, stroke=O, stroke_width=4, stroke_linejoin='round'))
        u.append(Ln(x + sx * 50 * sc, y + 86 * sc, x + sx * 44 * sc, y + 118 * sc, '#2B2118', 3))
    u.append(Pa(dd('M', x - 60 * sc, y + 2 * sc, 'Q', x, y - 22 * sc, x + 60 * sc, y + 2 * sc, 'L', x + 56 * sc, y + 24 * sc, 'Q', x, y + 6 * sc, x - 56 * sc, y + 24 * sc, 'Z'),
                fl, stroke=O, stroke_width=4, stroke_linejoin='round'))
    body = ''.join(u)
    return G(body, transform='rotate(%s %s %s)' % (n(tilt), n(x), n(y))) if tilt else body


def resident6(x, y):
    """Жилец кв. 6: свитер, треники, тапки; снимает ушанку, под ней вторая. x, y — таз."""
    s = []
    s.append(Pa(dd('M', x - 46, y, 'L', x - 56, y + 160, 'L', x - 12, y + 160, 'L', x - 2, y + 48, 'L', x + 10, y + 160, 'L', x + 54, y + 160, 'L', x + 46, y, 'Z'),
                '#3D5A8E', stroke=O, stroke_width=6, stroke_linejoin='round'))
    s += [E(x - 36, y + 90, 22, 26, '#4A69A2', stroke=O, stroke_width=4), E(x + 32, y + 90, 22, 26, '#4A69A2', stroke=O, stroke_width=4)]
    s += [E(x - 38, y + 168, 34, 14, '#7A3B2E', stroke=O, stroke_width=4), E(x + 36, y + 168, 34, 14, '#7A3B2E', stroke=O, stroke_width=4)]
    s.append(Pa(dd('M', x - 54, y + 6, 'Q', x - 62, y - 92, x - 38, y - 152, 'L', x + 38, y - 152, 'Q', x + 62, y - 92, x + 54, y + 6, 'Z'), '#8C3B32', stroke=O, stroke_width=6))
    s += [Ln(x - 56, y - 40 + k * 16, x + 56, y - 40 + k * 16, '#F4EEDC', 6, opacity='.85') for k in range(2)]
    s.append(Pa(dd('M', x - 24, y - 152, 'Q', x, y - 128, x + 24, y - 152), stroke=O, stroke_width=5))
    # левая рука вниз, правая поднята — держит снятую ушанку
    s.append(Pa(dd('M', x - 44, y - 140, 'Q', x - 78, y - 70, x - 54, y - 12), stroke=O, stroke_width=28, stroke_linecap='round'))
    s.append(Pa(dd('M', x - 44, y - 140, 'Q', x - 78, y - 70, x - 54, y - 12), stroke='#8C3B32', stroke_width=18, stroke_linecap='round'))
    s.append(C(x - 54, y - 8, 12, '#F0BD99', stroke=O, stroke_width=4))
    s.append(Pa(dd('M', x + 44, y - 140, 'Q', x + 92, y - 200, x + 80, y - 276), stroke=O, stroke_width=28, stroke_linecap='round'))
    s.append(Pa(dd('M', x + 44, y - 140, 'Q', x + 92, y - 200, x + 80, y - 276), stroke='#8C3B32', stroke_width=18, stroke_linecap='round'))
    s.append(C(x + 80, y - 282, 13, '#F0BD99', stroke=O, stroke_width=4))
    # голова
    s += [E(x, y - 196, 46, 52, 'url(#skinG)', stroke=O, stroke_width=5), E(x - 4, y - 172, 30, 20, '#4E6078', opacity='.22')]
    for sx in (-1, 1):
        s += [C(x + sx * 18, y - 196, 13, '#FFFFFF', stroke=O, stroke_width=4), C(x + sx * 16, y - 194, 5, O)]
        s.append(Ln(x + sx * 30, y - 214, x + sx * 8, y - 211, O, 4))
    s += [Ln(x - 4, y - 188, x + 4, y - 188, O, 4), Ln(x - 14, y - 166, x + 14, y - 166, O, 4)]
    s += [E(x - 30, y - 176, 9, 6, '#E88C7A', opacity='.6'), E(x + 30, y - 176, 9, 6, '#E88C7A', opacity='.6')]
    # на голове — вторая ушанка, в руке — первая
    s.append(ushanka(x, y - 226, 0.92))
    s.append(ushanka(x + 86, y - 318, 0.9, tilt=-12))
    return ''.join(s)


def scenes6():
    """Немая сцена 6 (§10): загорается газовая колонка; жилец снимает ушанку — под ней вторая. Панель на месте 1."""
    s = [R(0, 0, 1920, 1080, '#171B1E')]
    x0, y0, w, h = 60, 160, 580, 640
    clips = '<clipPath id="cq6"><rect x="%d" y="%d" width="%d" height="%d" rx="16"/></clipPath>' % (x0, y0, w, h)
    fl = y0 + h - 80
    b = [R(x0, y0, w, h, 'url(#tpY)'), R(x0, fl, w, 80, '#6B5B4B'), R(x0, y0, w, h, 'url(#vg2)')]
    hx, hy = x0 + 150, y0 + 250
    b.append(R(hx - 16, hy + 40, 32, fl - hy - 40, 'url(#cylGd)', stroke=O, stroke_width=4))
    b.append(G(gen2.heater2(hx, hy, 300, True, big=True), filter='url(#dsh)'))
    b.append(E(hx, hy - 60, 170, 170, 'url(#lamp)'))
    for k, (dx, dy, r) in enumerate(((210, -150, 18), (250, -60, 13), (190, 30, 11))):
        sx_, sy_ = hx + dx, hy + dy
        b.append(G(''.join(Ln(sx_ - math.cos(a) * r, sy_ - math.sin(a) * r, sx_ + math.cos(a) * r, sy_ + math.sin(a) * r, '#FFFFFF', 4)
                           for a in (0, math.pi / 3, 2 * math.pi / 3)), opacity='%.2f' % (.55 - k * .15)))
    b += [Pa(dd('M', hx + 150 + k * 26, hy - 20 - k * 30, 'q', -18, -22, 0, -44, 't', 0, -44), stroke='#FFFFFF', stroke_width=6, stroke_linecap='round', opacity='.55') for k in range(2)]
    b.append(G(resident6(x0 + 372, fl - 172), filter='url(#dsh)'))
    s.append(G(''.join(b), clip_path='url(#cq6)'))
    s.append(R(x0, y0, w, h, 'none', rx=16, stroke='#C99A2E', stroke_width=4))
    return ''.join(s), BASE + clips


def figure(x, y, sc=1.0, shirt='#F6F4EF', pants='#3D5A8E', hair='brown', arms=((-54, -12), (54, -12)), elbows=None,
           look=(0, 0), brows=None, mouth='flat', mustache=False, glasses=False, sleeves=None, tie=None, flip=False):
    """Жилец/гость немых сцен (по образцу resident()): x, y — таз, sc — масштаб.
    arms — кисти (левая, правая) относительно таза; elbows — контрольные точки дуги рук; sleeves — цвет рукава (None — голая рука).
    hair: brown | bald (лысина с венчиком) | bun (пучок) | hat (шляпа); brows: None | angry | up | sad; mouth: flat | frown | grit | o | smile."""
    s = []
    s.append(Pa(dd('M', -46, 0, 'L', -56, 160, 'L', -12, 160, 'L', -2, 48, 'L', 10, 160, 'L', 54, 160, 'L', 46, 0, 'Z'), pants, stroke=O, stroke_width=6, stroke_linejoin='round'))
    s += [E(-38, 168, 32, 13, '#3A2E26', stroke=O, stroke_width=4), E(36, 168, 32, 13, '#3A2E26', stroke=O, stroke_width=4)]
    s.append(Pa(dd('M', -52, 6, 'Q', -60, -92, -38, -152, 'L', 38, -152, 'Q', 60, -92, 52, 6, 'Z'), shirt, stroke=O, stroke_width=6))
    s.append(Pa(dd('M', -22, -152, 'Q', 0, -122, 22, -152), stroke=O, stroke_width=5))
    if tie:
        s.append(Pg([(0, -140), (-10, -126), (-6, -60), (0, -48), (6, -60), (10, -126)], tie, stroke=O, stroke_width=3))
    el = elbows or ((-80, -70), (80, -70))
    for sx, hand, eb in ((-1, arms[0], el[0]), (1, arms[1], el[1])):
        d = dd('M', sx * 42, -138, 'Q', eb[0], eb[1], hand[0], hand[1])
        s.append(Pa(d, stroke=O, stroke_width=28 if sleeves else 26, stroke_linecap='round'))
        s.append(Pa(d, stroke=sleeves or '#F0BD99', stroke_width=18 if sleeves else 16, stroke_linecap='round'))
        if sleeves:
            s.append(C(hand[0], hand[1], 12, '#F0BD99', stroke=O, stroke_width=4))
    hy = -196
    s += [E(0, hy, 46, 52, 'url(#skinG)', stroke=O, stroke_width=5), E(-4, hy + 24, 30, 20, '#4E6078', opacity='.22')]
    if hair == 'brown':
        s.append(Pa(dd('M', -42, hy - 18, 'Q', -30, hy - 66, 4, hy - 54, 'Q', 40, hy - 66, 44, hy - 18, 'Q', 20, hy - 40, -42, hy - 18, 'Z'), '#6B4B32', stroke=O, stroke_width=4))
    elif hair == 'bald':
        for sx in (-1, 1):
            s.append(Pa(dd('M', sx * 44, hy - 4, 'Q', sx * 50, hy - 30, sx * 30, hy - 40, 'Q', sx * 40, hy - 20, sx * 36, hy + 6, 'Z'), '#3B2A1E', stroke=O, stroke_width=3))
        s.append(Pa(dd('M', -20, hy - 40, 'Q', 0, hy - 50, 18, hy - 42), stroke='#FFFFFF', stroke_width=5, stroke_linecap='round', opacity='.6'))
    elif hair == 'bun':
        s.append(C(0, hy - 62, 22, '#8A3A26', stroke=O, stroke_width=4))
        s.append(Pa(dd('M', -46, hy + 6, 'Q', -50, hy - 60, 0, hy - 56, 'Q', 50, hy - 60, 46, hy + 6, 'Q', 36, hy - 30, 0, hy - 34, 'Q', -36, hy - 30, -46, hy + 6, 'Z'),
                    '#A0452C', stroke=O, stroke_width=4, stroke_linejoin='round'))
    elif hair == 'hat':
        s.append(E(0, hy - 34, 66, 13, '#4A4036', stroke=O, stroke_width=4))
        s.append(Pa(dd('M', -38, hy - 36, 'Q', -40, hy - 86, 0, hy - 84, 'Q', 40, hy - 86, 38, hy - 36, 'Z'), '#5C5044', stroke=O, stroke_width=4))
        s.append(R(-38, hy - 50, 76, 12, '#2E2620'))
    lx, ly = look
    for sx in (-1, 1):
        s += [C(sx * 18, hy - 2, 13, '#FFFFFF', stroke=O, stroke_width=4), C(sx * 18 + lx * 6, hy + ly * 6, 5, O)]
        if brows == 'angry':
            s.append(Ln(sx * 32, hy - 24, sx * 8, hy - 14, O, 5))
        elif brows == 'up':
            s.append(Ln(sx * 30, hy - 26, sx * 8, hy - 28, O, 4))
        elif brows == 'sad':
            s.append(Ln(sx * 30, hy - 14, sx * 8, hy - 24, O, 4))
        elif brows == 'flat':
            s.append(Ln(sx * 30, hy - 13, sx * 6, hy - 13, O, 5))
    if glasses:
        s += [C(sx * 18, hy - 2, 18, 'none', stroke=O, stroke_width=4) for sx in (-1, 1)] + [Ln(-1, hy - 4, 1, hy - 4, O, 4)]
    s.append(Ln(-4, hy + 8, 4, hy + 8, O, 4))
    my = hy + 30
    if mouth == 'flat':
        s.append(Ln(-12, my, 12, my, O, 4))
    elif mouth == 'frown':
        s.append(Pa(dd('M', -14, my + 4, 'Q', 0, my - 6, 14, my + 4), stroke=O, stroke_width=4, stroke_linecap='round'))
    elif mouth == 'smile':
        s.append(Pa(dd('M', -14, my - 3, 'Q', 0, my + 8, 14, my - 3), stroke=O, stroke_width=4, stroke_linecap='round'))
    elif mouth == 'o':
        s.append(E(0, my + 2, 7, 9, '#5A2A22', stroke=O, stroke_width=3))
    elif mouth == 'grit':
        s.append(R(-16, my - 6, 32, 13, '#FFFFFF', rx=4, stroke=O, stroke_width=3))
        s += [Ln(-16 + k * 8, my - 6, -16 + k * 8, my + 7, O, 2) for k in (1, 2, 3)]
    if mustache:
        s.append(Pa(dd('M', 0, hy + 14, 'Q', -14, hy + 12, -30, hy + 26, 'Q', -12, hy + 26, 0, hy + 20, 'Q', 12, hy + 26, 30, hy + 26, 'Q', 14, hy + 12, 0, hy + 14, 'Z'),
                    '#3B2A1E', stroke=O, stroke_width=3, stroke_linejoin='round'))
    tf = 'translate(%s %s) scale(%s%s %s)' % (n(x), n(y), '-' if flip else '', n(sc), n(sc))
    return G(''.join(s), transform=tf)


def spark(x, y, r, col='#FFFFFF'):
    return Pg([(x, y - r), (x + r * .3, y - r * .3), (x + r, y), (x + r * .3, y + r * .3), (x, y + r), (x - r * .3, y + r * .3), (x - r, y), (x - r * .3, y - r * .3)], col)


def bubble(x, y, w, h, tx, ty, txt, rot=0):
    """Облачко-выкрик без слов: только знаки."""
    b = E(x, y, w, h, '#FFFFFF', stroke=O, stroke_width=5)
    b += Pg([(x - w * .2, y + h * .7), (tx, ty), (x + w * .15, y + h * .8)], '#FFFFFF', stroke=O, stroke_width=5, stroke_linejoin='round')
    b += E(x, y, w - 3, h - 3, '#FFFFFF')
    b += T(x, y + h * .42, txt, h * 1.25, '#C83E2C', weight='bold', anchor='middle')
    return G(b, transform='rotate(%s %s %s)' % (n(rot), n(x), n(y))) if rot else b


def drop_(x, y, r, col=None):
    col = col or Q['water']
    return Pa(dd('M', x, y - r * 1.9, 'Q', x + r * 1.05, y - r * .3, x + r, y + r * .1, 'A', r, r, 0, 1, 1, x - r, y + r * .1, 'Q', x - r * 1.05, y - r * .3, x, y - r * 1.9, 'Z'),
              col, stroke=O, stroke_width=max(2, r * .22), stroke_linejoin='round')


def scene_fountain(x0, y0, w, h):
    """Кв. 6 «Дали напор»: фонтан из унитаза пробил перекрытие; сосед сверху стоит с ведром и смотрит в дыру."""
    fl = y0 + h - 80
    uf, sl = y0 + 262, 44                       # пол верхней квартиры, толщина плиты
    b = [R(x0, y0, w, uf - y0, 'url(#tpY)'), R(x0, uf + sl, w, fl - uf - sl, 'url(#tpB)'), R(x0, fl, w, 80, '#6B5B4B'),
         R(x0, uf - 18, w, 18, '#7A5A3E'), R(x0, uf, w, sl, '#A39C90'), Ln(x0, uf + sl, x0 + w, uf + sl, O, 5), Ln(x0, uf - 18, x0 + w, uf - 18, O, 4)]
    b += [C(x0 + 30 + k * 64, uf + sl / 2 + (k % 2) * 6 - 3, 5, '#6E675C') for k in range(10)]
    tx, ty, tc = x0 + 150, fl - 70, 250
    jx = tx + .21 * tc                           # ось струи — над чашей
    hx0, hx1 = jx - 46, jx + 52
    b.append(Pg([(hx0, uf - 18), (hx0 + 14, uf + 8), (hx0 - 6, uf + 24), (hx0 + 8, uf + sl), (hx1 - 4, uf + sl), (hx1 + 8, uf + 22), (hx1 - 8, uf + 6), (hx1, uf - 18)],
                '#2A2622', stroke=O, stroke_width=4, stroke_linejoin='round'))
    b.append(E(tx + .2 * tc, fl + 10, 150, 14, 'url(#waterG)', stroke=O, stroke_width=3, opacity='.85'))
    b.append(G(toilet2(tx, ty, tc, True), filter='url(#dsh)'))
    top = y0 + 112
    b.append(R(jx - 22, top, 44, ty - .1 * tc - top, 'url(#waterG)', rx=18, stroke=O, stroke_width=5))
    b += [Ln(jx - 8, top + 30 + k * 70, jx - 8, top + 70 + k * 70, '#FFFFFF', 5, opacity='.8') for k in range(6)]
    for sx in (-1, 1):
        b.append(Pa(dd('M', jx, top + 6, 'Q', jx + sx * 70, top - 50, jx + sx * 120, top + 40), stroke=O, stroke_width=20, stroke_linecap='round'))
        b.append(Pa(dd('M', jx, top + 6, 'Q', jx + sx * 70, top - 50, jx + sx * 120, top + 40), stroke=Q['water'], stroke_width=11, stroke_linecap='round'))
    b += [drop_(jx + dx, top + dy, r) for dx, dy, r in ((-150, 80, 9), (148, 96, 10), (-96, 120, 7), (178, 40, 7), (-40, -30, 8))]
    for dx, dy, a in ((-80, uf - 40, 20), (96, uf - 64, -30), (-120, uf + 120, 35), (110, uf + 150, -15)):
        b.append(Pg([(jx + dx - 12, dy - 8), (jx + dx + 14, dy - 10), (jx + dx + 10, dy + 10), (jx + dx - 8, dy + 12)], '#A39C90', stroke=O, stroke_width=3,
                    transform='rotate(%d %s %s)' % (a, n(jx + dx), n(dy))))
    # сосед: таз выше пола на длину ног; ведро в опущенной руке, смотрит вниз, в дыру
    nx, ny, ns = x0 + 450, uf - 18 - 170 * .56, .56
    b.append(G(figure(nx, ny, ns, shirt='#5E7F5A', pants='#4A4036', hair='bald', mustache=True, arms=((-150, -150), (52, -10)), elbows=((-100, -170), (78, -70)),
                      look=(-1, 1), brows='up', mouth='o', sleeves=None), filter='url(#dsh)'))
    bx, by = nx - 150 * ns, ny - 150 * ns + 14
    b.append(G(Pa(dd('M', bx - 30, by - 4, 'Q', bx - 2, by - 40, bx + 26, by - 4), stroke=O, stroke_width=4) +
               Pg([(bx - 28, by), (bx + 28, by), (bx + 20, by + 50), (bx - 20, by + 50)], '#B9C2CB', stroke=O, stroke_width=5, stroke_linejoin='round') +
               E(bx, by, 28, 7, '#7E8892', stroke=O, stroke_width=4), filter='url(#dsh)'))
    return b


def scene_hose(x0, y0, w, h):
    """Кв. 7 «Брандспойт»: струя только что потушила сигарету; жилец мокрый, невозмутимо закуривает новую."""
    fl = y0 + h - 80
    b = [R(x0, y0, w, h, 'url(#tpY)'), R(x0, fl, w, 80, '#6B5B4B'), R(x0, y0, w, h, 'url(#vg2)')]
    rx_, ry_ = x0 + 380, fl - 172
    my = ry_ - 166                                # уровень рта
    # брандспойт в стене слева: латунный ствол, с него ещё капает
    nx, ny = x0 + 40, my - 6
    b.append(R(x0 - 10, ny - 34, 70, 68, '#B83A2C', rx=10, stroke=O, stroke_width=5))
    b.append(Pg([(nx + 20, ny - 16), (nx + 96, ny - 9), (nx + 96, ny + 9), (nx + 20, ny + 16)], 'url(#cylGd)', stroke=O, stroke_width=5, stroke_linejoin='round'))
    b.append(R(nx + 92, ny - 12, 14, 24, '#C99A2E', rx=3, stroke=O, stroke_width=4))
    b += [drop_(nx + 104, ny + 30 + k * 34, 7 - k) for k in range(2)]
    # след струи — пунктир капель до того места, где была сигарета
    b += [drop_(nx + 140 + k * 36, ny + (k - 3) ** 2 * 1.5 - 8, 5) for k in range(4)]
    b.append(G(figure(rx_, ry_, 1.0, shirt='#F6F4EF', pants='#3D5A8E', hair='bald', mustache=True, arms=((-54, -12), (-14, -150)), elbows=((-80, -70), (40, -60)),
                      look=(1, .3), brows='flat', mouth='flat'), filter='url(#dsh)'))
    # мокрая голова: капли с лысины и усов
    b += [drop_(rx_ + dx, ry_ - 196 + dy, r) for dx, dy, r in ((-52, -10, 7), (50, 10, 6), (-30, 46, 6), (24, 52, 5))]
    # новая сигарета — одна линия, спичка с огоньком у кончика
    cx_, cy_ = rx_ - 14, my - 1
    b.append(Ln(cx_, cy_, cx_ - 44, cy_ + 6, O, 9))
    b.append(Ln(cx_, cy_, cx_ - 44, cy_ + 6, '#FBF8F0', 5))
    b.append(Ln(cx_ - 34, cy_ + 4.5, cx_ - 44, cy_ + 6, '#D0703A', 5))
    mx_, my_ = rx_ - 14, ry_ - 150
    b.append(Ln(mx_ - 10, my_ + 14, mx_ - 46, my_ + 2, '#D9B57A', 5))
    b.append(Pa(dd('M', mx_ - 50, my_ + 6, 'Q', mx_ - 62, my_ - 10, mx_ - 50, my_ - 24, 'Q', mx_ - 40, my_ - 8, mx_ - 50, my_ + 6, 'Z'), '#F4B23C', stroke='#C0521F', stroke_width=2))
    # старая — переломлена, в луже
    px_, py_ = x0 + 230, fl + 22
    b.append(E(px_, py_, 70, 12, 'url(#waterG)', stroke=O, stroke_width=3, opacity='.9'))
    b.append(Pa(dd('M', px_ - 30, py_ - 2, 'L', px_ - 4, py_ - 6, 'L', px_ + 22, py_ - 18), stroke=O, stroke_width=9, stroke_linecap='round', stroke_linejoin='round'))
    b.append(Pa(dd('M', px_ - 30, py_ - 2, 'L', px_ - 4, py_ - 6, 'L', px_ + 22, py_ - 18), stroke='#E8E2CF', stroke_width=5, stroke_linecap='round', stroke_linejoin='round'))
    b.append(Ln(px_ + 14, py_ - 14, px_ + 22, py_ - 18, '#5A5048', 5))
    return b


def scene_comb(x0, y0, w, h):
    """Кв. 8 «Гребёнка»: двое одновременно открыли краны с одной гребёнки — у обоих по капле; немая ссора."""
    fl = y0 + h - 80
    b = [R(x0, y0, w, h, 'url(#tpM)'), R(x0, fl, w, 80, '#6B5B4B'), R(x0, y0, w, h, 'url(#vg2)')]
    gy, ax, bx_ = y0 + 236, x0 + 196, x0 + 384
    # гребёнка: стояк сверху, коллектор, два отвода с вентилями
    b.append(R(x0 + 274, y0 - 10, 32, gy - y0 + 10, 'url(#cylGd)', stroke=O, stroke_width=5))
    b.append(R(ax - 30, gy - 20, bx_ - ax + 60, 40, 'url(#cylGd)', rx=14, stroke=O, stroke_width=5))
    for k in range(4):
        b.append(R(ax - 6 + k * (bx_ - ax) / 3, gy - 24, 12, 48, '#C99A2E', rx=3, stroke=O, stroke_width=3))
    for x in (ax, bx_):
        b.append(R(x - 13, gy + 16, 26, 74, 'url(#cylGd)', stroke=O, stroke_width=5))
        b.append(C(x, gy + 52, 24, '#C83E2C', stroke=O, stroke_width=5))
        b += [Ln(x - 22, gy + 52, x + 22, gy + 52, '#7A231A', 4), Ln(x, gy + 30, x, gy + 74, '#7A231A', 4), C(x, gy + 52, 7, '#C99A2E', stroke=O, stroke_width=2)]
        b.append(R(x - 16, gy + 88, 32, 16, '#C99A2E', rx=4, stroke=O, stroke_width=4))
        b.append(drop_(x, gy + 132, 7))
    # ведро под левым краном, таз под правым — оба сухие
    b.append(G(Pg([(ax - 44, fl - 70), (ax + 44, fl - 70), (ax + 34, fl + 6), (ax - 34, fl + 6)], '#B9C2CB', stroke=O, stroke_width=5, stroke_linejoin='round')
               + E(ax, fl - 70, 44, 10, '#6E7781', stroke=O, stroke_width=4), filter='url(#dsh)'))
    b.append(G(Pa(dd('M', bx_ - 70, fl - 30, 'L', bx_ + 70, fl - 30, 'L', bx_ + 52, fl + 8, 'L', bx_ - 52, fl + 8, 'Z'), '#E2E6DA', stroke=O, stroke_width=5, stroke_linejoin='round')
               + E(bx_, fl - 30, 70, 10, '#9AA39A', stroke=O, stroke_width=4), filter='url(#dsh)'))
    # она — слева, он — справа; каждый держит свой вентиль и смотрит на другого
    sc = .82
    b.append(G(figure(x0 + 92, fl - 172 * sc, sc, shirt='#D9739A', pants='#5C4A6E', hair='bun', arms=((-54, -10), (128, -232)), elbows=((-80, -70), (110, -120)),
                      look=(1, 0), brows='angry', mouth='frown', sleeves='#D9739A'), filter='url(#dsh)'))
    b.append(G(figure(x0 + 488, fl - 172 * sc, sc, shirt='#F6F4EF', pants='#3D5A8E', hair='bald', mustache=True, arms=((-128, -232), (54, -10)),
                      elbows=((-110, -120), (80, -70)), look=(-1, 0), brows='angry', mouth='grit'), filter='url(#dsh)'))
    # полотенце на плече у него
    tx, ty = x0 + 488 + 26 * sc, fl - 172 * sc - 150 * sc
    b.append(Pa(dd('M', tx - 8, ty - 4, 'L', tx + 26, ty + 2, 'L', tx + 30, ty + 80, 'L', tx + 6, ty + 84, 'Z'), '#F2C14E', stroke=O, stroke_width=4, stroke_linejoin='round'))
    b.append(bubble(x0 + 110, y0 + 92, 64, 44, x0 + 104, y0 + 160, '!', rot=-6))
    b.append(bubble(x0 + 470, y0 + 86, 76, 48, x0 + 478, y0 + 160, '!!', rot=5))
    b += [Ln(x0 + 268 + k * 22, y0 + 84 + (k % 2) * 16, x0 + 280 + k * 22, y0 + 98 - (k % 2) * 16, '#FFFFFF', 5, opacity='.75') for k in range(3)]
    return b


def scene_test(x0, y0, w, h):
    """Кв. 9 «Опрессовка»: манометр в красной зоне; комиссия с папкой и печатью смотрит на единственную каплю."""
    fl = y0 + h - 80
    b = [R(x0, y0, w, h, 'url(#tpB)'), R(x0, fl, w, 80, '#6B5B4B'), R(x0, y0, w, h, 'url(#vg2)')]
    # труба вдоль стены с манометром
    py = y0 + 140
    b.append(R(x0 - 10, py - 18, w + 20, 36, 'url(#cylGd)', stroke=O, stroke_width=5))
    gx, gy = x0 + 290, py - 64
    b.append(R(gx - 9, gy + 20, 18, 30, 'url(#cylGd)', stroke=O, stroke_width=4))
    b.append(C(gx, gy, 46, '#F4F1EA', stroke=O, stroke_width=6))
    b.append(Pa(dd('M', gx + 30, gy - 18, 'A', 35, 35, 0, 0, 1, gx + 30, gy + 18), stroke='#C83E2C', stroke_width=9))
    b += [Ln(gx + math.cos(a) * 30, gy + math.sin(a) * 30, gx + math.cos(a) * 38, gy + math.sin(a) * 38, O, 3)
          for a in [math.pi * (.75 + k * .25) for k in range(7)]]
    b.append(Ln(gx, gy, gx + 34, gy + 10, '#C83E2C', 5))
    b.append(C(gx, gy, 6, O))
    for x in (x0 + 90, x0 + 490):
        b.append(R(x - 8, py - 22, 16, 44, '#C99A2E', rx=3, stroke=O, stroke_width=3))
    # капля и крошечная лужица — точно посередине
    dx_, dy_ = x0 + 290, fl + 30
    b.append(E(dx_, dy_ + 4, 26, 6, 'url(#waterG)', stroke=O, stroke_width=2.5))
    b.append(drop_(dx_, dy_ - 14, 10))
    b.append(Pa(dd('M', dx_ - 12, dy_ - 30, 'L', dx_ - 30, dy_ - 44), stroke='#FFFFFF', stroke_width=4, stroke_linecap='round', opacity='.7'))
    # комиссия: слева — в шляпе, с раскрытой папкой и ручкой; справа — в очках, печать занесена
    sc = .9
    lx, rx_ = x0 + 140, x0 + 446
    hip = fl - 172 * sc
    b.append(G(figure(lx, hip, sc, shirt='#6E6A62', pants='#4A4640', hair='hat', arms=((60, -70), (70, -110)), elbows=((10, -40), (100, -70)),
                      look=(1, 1), brows='flat', mouth='flat', mustache=True, sleeves='#6E6A62', tie='#8C3B32'), filter='url(#dsh)'))
    fx, fy = lx + 66 * sc, hip - 96 * sc
    b.append(G(R(fx - 50, fy - 40, 100, 74, '#8C5A32', rx=4, stroke=O, stroke_width=4, transform='rotate(-14 %s %s)' % (n(fx), n(fy)))
               + R(fx - 42, fy - 34, 84, 62, '#F4EEDC', stroke=O, stroke_width=3, transform='rotate(-14 %s %s)' % (n(fx), n(fy)))
               + ''.join(Ln(fx - 32, fy - 20 + k * 14, fx + 30, fy - 20 + k * 14, '#9A9480', 3, transform='rotate(-14 %s %s)' % (n(fx), n(fy))) for k in range(4))))
    b.append(G(figure(rx_, hip, sc, shirt='#4E5A6A', pants='#3A4250', hair='bald', arms=((-60, -60), (40, -300)), elbows=((-90, -50), (90, -220)),
                      look=(-1, 1), brows='up', mouth='flat', glasses=True, sleeves='#4E5A6A', tie='#2F5E9E'), filter='url(#dsh)'))
    sx_, sy_ = rx_ + 40 * sc, hip - 300 * sc
    b.append(G(E(sx_, sy_ - 34, 14, 12, '#8C5A32', stroke=O, stroke_width=4) + R(sx_ - 6, sy_ - 26, 12, 22, '#A8744A', stroke=O, stroke_width=3)
               + R(sx_ - 26, sy_ + 6, 52, 14, '#2B56B8', rx=3, stroke=O, stroke_width=4) + R(sx_ - 20, sy_ - 6, 40, 14, '#3A3129', stroke=O, stroke_width=3), filter='url(#dsh)'))
    return b


def scenes7_10(page=0):
    """Немые сцены кв. 6–9 (сюжеты старых кв. 7–10, §10). Те же панели 580×640, что в scenes2(): page 0 — кв. 6, 7, 8; page 1 — кв. 9."""
    s = [R(0, 0, 1920, 1080, '#171B1E')]
    clips = ''
    fns = ((scene_fountain, scene_hose, scene_comb), (scene_test,))[page]
    for i, fn in enumerate(fns):
        x0, y0, w, h = 60 + i * 610, 160, 580, 640
        clips += '<clipPath id="cr%d"><rect x="%d" y="%d" width="%d" height="%d" rx="16"/></clipPath>' % (i, x0, y0, w, h)
        b = fn(x0, y0, w, h)
        s.append(G(''.join(b), clip_path='url(#cr%d)' % i))
        s.append(R(x0, y0, w, h, 'none', rx=16, stroke='#C99A2E', stroke_width=4))
    return ''.join(s), BASE + clips


# ---------------------------------------------------------------- лист элементов

def gallery2():
    s = [R(0, 0, 1920, 1640, '#1E2428'), T(60, 86, 'Элементы поля и героя — утверждённый стиль', 54, Q['cream'], weight='bold'),
         T(60, 130, 'Закреплённое темнее и на хомуте, подвижная латунь ярче. Н — штуцер с витками, В — шестигранное гнездо. У каждой детали мягкая тень.', 29, '#AEB9C0')]

    def tile(col, row, label, fn, span=1):
        x0, y0, w, th = 60 + col * 226, 164 + row * 318, span * 226 - 16, 294
        s.append(R(x0, y0, w, th, '#2A3136', rx=14))
        s.append(R(x0 + 10, y0 + 10, w - 20, 76, Q['wash']) + R(x0 + 10, y0 + 86, w - 20, th - 164, 'url(#panelG)') + R(x0 + 10, y0 + 82, w - 20, 8, Q['stripe']))
        s.append(G(fn(x0 + w / 2, y0 + 128), filter='url(#dsh)'))
        s.extend(T(x0 + w / 2, y0 + th - 44 + k * 30, ln, 27, Q['cream'], anchor='middle') for k, ln in enumerate(wrap(label, 17 * span)))

    def wall(pid):
        return lambda x, y: R(x - 80, y - 58, 160, 116, 'url(#%s)' % pid, rx=34, stroke=O, stroke_width=9, filter='url(#wob)')
    rows = [
        [('Кладка · кв. 1', wall('tpM')), ('Кладка · кв. 2', wall('tpB')), ('Кладка · кв. 3', wall('tpY')),
         ('Слив', lambda x, y: drain2(x, y, 104, bottom=y + 90)), ('Стояк · выход В', lambda x, y: source2(x, y, 104, {'right': 'V'}, y - 95, y + 95)),
         ('Глухой отвод · Н', lambda x, y: stub2(x, y, 104, 'right', 'N', 'left')), ('Глухой отвод · В', lambda x, y: stub2(x, y, 104, 'down', 'V', 'up')),
         ('Фаянс', lambda x, y: porcelain2(x, y, 104))],
        [('Ванна · сухая', lambda x, y: bath2(x - 10, y, 96) + port2(x - 10, y, 96, 'left', 'N', True)), ('Ванна · с водой', lambda x, y: bath2(x - 10, y, 96, True) + port2(x - 10, y, 96, 'left', 'N', True)),
         ('Унитаз · сухой', lambda x, y: toilet2(x + 8, y + 8, 92) + port2(x + 8, y + 6, 92, 'left', 'N', True)), ('Унитаз · с водой', lambda x, y: toilet2(x + 8, y + 8, 92, True) + port2(x + 8, y + 6, 92, 'left', 'N', True)),
         ('Мойка · сухая', lambda x, y: sink2(x + 4, y + 6, 94) + port2(x + 4, y + 4, 94, 'left', 'N', True)), ('Мойка · с водой', lambda x, y: sink2(x + 4, y + 6, 94, True) + port2(x + 4, y + 4, 94, 'left', 'N', True)),
         ('Протечка без напора: капает', lambda x, y: stub2(x, y - 22, 90, 'down', 'V', 'up') + gen.drop(x, y + 50, 13) + gen.drop(x, y + 88, 9)),
         ('Струя под напором (кв. 7–10)', lambda x, y: stub2(x, y + 54, 90, 'up', 'V', 'down') + gen.jet(x, y + 6, 118, 90))],
        [('Муфта (кв. 4+)', lambda x, y: fitting2(x, y, 104, {'left': 'V', 'right': 'N'})), ('Угольник', lambda x, y: fitting2(x, y, 104, {'left': 'V', 'down': 'N'})),
         ('Тройник', lambda x, y: fitting2(x, y, 104, {'left': 'V', 'right': 'N', 'down': 'N'})), ('Заглушка', lambda x, y: fitting2(x, y, 104, {'left': 'V'})),
         ('Ноги вкручены: пух ленты', lambda x, y: port2(x + 52, y, 104, 'left', 'V', True) + heelL((x - 40, y), 'right', 104, True, True)),
         ('Голова вцепилась в резьбу', lambda x, y: port2(x + 50, y, 104, 'left', 'N', True) + headL((x - 44, y), 'right', 104, True, True)),
         ('Кнопки: отмена, заново', lambda x, y: button2('undo', x - 56, y) + button2('restart', x + 56, y)),
         ('Кнопки: подсказка, меню', lambda x, y: button2('hint', x - 56, y) + button2('menu', x + 56, y))]]
    for r, items in enumerate(rows):
        for col, (lab, fn) in enumerate(items):
            tile(col, r, lab, fn)
    r3 = [('Голова ходит, ноги спят: пальцы поджаты', lambda x, y: hero([(x - 96, y), (x, y), (x + 96, y)], 96, 2, 4)),
          ('Сжат до 2: рёбра гуще. Ходят ноги', lambda x, y: hero([(x + 48, y), (x - 48, y)], 96, 2, 4, active='heel')),
          ('Растянут до 4 с изгибом: рёбра реже', lambda x, y: hero([(x - 126, y + 36), (x - 42, y + 36), (x + 42, y + 36), (x + 42, y - 48)], 84, 2, 4)),
          ('Вода идёт насквозь: стояк → Лапидус → ванна', lambda x, y: source2(x - 168, y, 84, {'right': 'V'}, y - 80, y + 80)
           + hero([(x - 84, y), (x, y), (x + 84, y)], 84, 2, 4, ring=False, wet=True, screwed=(True, True)) + bath2(x + 168, y, 84, True) + port2(x + 168, y, 84, 'left', 'N', True))]
    for col, (lab, fn) in enumerate(r3):
        tile(col * 2, 3, lab, fn, span=2)
    s.append(T(60, 1620, 'Все макеты — стартовые позиции и примеры состояний; решений уровней здесь нет.', 28, '#8E9AA3'))
    return ''.join(s), BASE


JOBS = [('01_gallery', gallery2, 1640), ('02_level1', lambda: level(0), 1080), ('03_level2', lambda: level(1), 1080),
        ('04_level3', lambda: level(2, 3, overlay=toast2('Голова по мылу скользит')), 1080), ('05_menu', menu2, 1080), ('06_select', select2, 1080),
        ('07_request', request2, 1080), ('08_hint', hint2, 1080), ('09_act', act2, 1080), ('10_passport', passport2, 1080),
        ('11_washed', washed2, 1080), ('12_scenes', scenes2, 1080)]

if __name__ == '__main__':
    for name, fn, h in JOBS:
        try:
            body, extra = fn()
            render(name, body, extra, 1920, h)
            print('ok', name)
        except Exception:
            print('FAIL', name)
            traceback.print_exc()
