#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/scenes3.py — немые сцены после победы (§10) для нынешних квартир 1–10: приборы — из Blender (крупные спрайты
build/fx_hi, art/fx_compose.py с FX_RES=960), плитка — с фасками, как кладка квартир; люди и реквизит — рисунок (как голова
Лапидуса, решение Lao 03.10). Панель 580×640 в золотой рамке → assets/gfx/sceneN.png (588×648).
   FX_RES=960 xvfb-run -a blender -b -P art/blender/fixtures.py -- build/fx3d_hi
   FX_RES=960 FX_OUT=build/fx_hi python3 art/fx_compose.py build/fx3d_hi
   python3 art/scenes3.py [номера]"""
import base64, math, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2, hero_png
from gen import n, R, C, E, Ln, Pg, Pa, G, T, dd
from gen2 import Q

hero_png.use_in(screens2)        # плитка с фасками (tile_pat) и прочее
from screens2 import figure, resident, resident6, ushanka, bubble, spark, drop_, BASE
BASE = screens2.BASE
O = Q['ol']
ROOT = gen2.ROOT
HI = os.path.join(ROOT, 'build', 'fx_hi')
OUT = os.path.join(ROOT, 'assets', 'gfx')
TMP = os.path.join(ROOT, 'build', 'gfx_svg')
FXS = {m.group(1): (float(m.group(2)), float(m.group(3)))
       for m in re.finditer(r'(\w+) = \{ ([\d.]+), ([\d.]+) \}', open(os.path.join(ROOT, 'game', 'fx_sizes.lua')).read())}
X0, Y0, W, H = 4, 4, 580, 640
FL = Y0 + H - 80
_B = {}


def fx(what, wet, cx, bottom, width, flip=False, rot=0):
    """Прибор из Blender: габарит шириной width px, низ — на bottom, центр по x — cx."""
    fw, fh = FXS[what]
    c = width / fw                    # px на клетку; спрайт = 2 клетки, габарит в центре
    cy = bottom - fh * c / 2
    name = 'fx_%s_%s' % (what, 'wet' if wet else 'dry')
    if name not in _B:
        _B[name] = base64.b64encode(open(os.path.join(HI, name + '.png'), 'rb').read()).decode()
    tr = 'translate(%.1f %.1f) rotate(%s) scale(%s 1)' % (cx, cy, rot, -1 if flip else 1)
    return '<g transform="%s"><image x="%.1f" y="%.1f" width="%.1f" height="%.1f" xlink:href="data:image/png;base64,%s"/></g>' % (
        tr, -c, -c, 2 * c, 2 * c, _B[name]), c, cy


def room(tile):
    return [R(X0, Y0, W, H, 'url(#%s)' % tile), R(X0, FL, W, 80, '#6B5B4B'), Ln(X0, FL, X0 + W, FL, O, 4), R(X0, Y0, W, H, 'url(#vg2)')]


def steam(x, y, k=3, gap=26, h=44, op=.6):
    return ''.join(Pa(dd('M', x + i * gap, y - (i % 2) * 14, 'q', -16, -h / 2, 0, -h, 't', 0, -h), stroke='#FFFFFF', stroke_width=6,
                      stroke_linecap='round', opacity='%.2f' % op) for i in range(k))


def cloud(x, y, r, op=.85):
    return ''.join(C(x + dx * r, y + dy * r, rr * r, '#F4F7FA', opacity='%.2f' % op) for dx, dy, rr in
                   ((-.9, .1, .7), (-.3, -.25, .9), (.4, -.15, .85), (1.0, .15, .65), (0, .3, .8)))


def cat(x, y, k=1.0, drink=False):
    """Рыжий кот сидит (x, y — низ у задних лап), смотрит влево; drink — тянется мордой вперёд-вниз."""
    f, fd = '#E08A3C', '#B5642A'
    s = [Pa(dd('M', x + 40 * k, y - 10 * k, 'Q', x + 92 * k, y - 20 * k, x + 84 * k, y - 70 * k, 'Q', x + 80 * k, y - 96 * k, x + 98 * k, y - 104 * k),
            stroke=O, stroke_width=16 * k, stroke_linecap='round'),
         Pa(dd('M', x + 40 * k, y - 10 * k, 'Q', x + 92 * k, y - 20 * k, x + 84 * k, y - 70 * k, 'Q', x + 80 * k, y - 96 * k, x + 98 * k, y - 104 * k),
            stroke=f, stroke_width=9 * k, stroke_linecap='round'),
         E(x + 10 * k, y - 46 * k, 48 * k, 46 * k, f, stroke=O, stroke_width=4),
         E(x + 30 * k, y - 4 * k, 26 * k, 9 * k, fd, stroke=O, stroke_width=3)]
    s += [Ln(x + (2 + i * 14) * k, y - 84 * k, x + (8 + i * 14) * k, y - 60 * k, fd, 5 * k) for i in range(3)]
    hx, hy = (x - 46 * k, y - 66 * k) if drink else (x - 30 * k, y - 96 * k)
    s.append(Pg([(hx - 26 * k, hy - 14 * k), (hx - 20 * k, hy - 46 * k), (hx - 2 * k, hy - 24 * k)], f, stroke=O, stroke_width=4, stroke_linejoin='round'))
    s.append(Pg([(hx + 6 * k, hy - 24 * k), (hx + 22 * k, hy - 46 * k), (hx + 28 * k, hy - 12 * k)], f, stroke=O, stroke_width=4, stroke_linejoin='round'))
    s.append(E(hx, hy, 32 * k, 28 * k, f, stroke=O, stroke_width=4))
    if drink:   # глаза зажмурены от удовольствия, язык к струе
        s += [Pa(dd('M', hx + dx * k - 7 * k, hy - 4 * k, 'q', 7 * k, 6 * k, 14 * k, 0), stroke=O, stroke_width=3, stroke_linecap='round') for dx in (-12, 10)]
        s.append(E(hx - 20 * k, hy + 22 * k, 6 * k, 9 * k, '#E2687A', stroke=O, stroke_width=2))
    else:
        s += [C(hx + dx * k, hy - 4 * k, 5 * k, O) for dx in (-12, 10)]
    s.append(C(hx - 2 * k, hy + 8 * k, 4 * k, '#5A2A22'))
    return ''.join(s)


def sock(x, y, col='#C0413A', k=1.0):
    d = dd('M', x - 14 * k, y, 'L', x - 14 * k, y + 60 * k, 'Q', x - 14 * k, y + 80 * k, x + 12 * k, y + 80 * k, 'L', x + 32 * k, y + 80 * k,
           'Q', x + 44 * k, y + 80 * k, x + 44 * k, y + 66 * k, 'Q', x + 44 * k, y + 54 * k, x + 24 * k, y + 52 * k, 'L', x + 14 * k, y + 52 * k, 'L', x + 14 * k, y, 'Z')
    return (Pa(d, col, stroke=O, stroke_width=4, stroke_linejoin='round') + ''.join(Ln(x - 14 * k, y + (10 + i * 16) * k, x + 14 * k, y + (10 + i * 16) * k, '#F4EEDC', 6 * k) for i in range(3)))


def sc1():
    b = room('tpM')
    img, c, cy = fx('bath', True, X0 + 250, FL + 14, 430)
    b.append(Pa(dd('M', X0 + 40, Y0 + 210, 'q', -10, 80, 14, 170), stroke=O, stroke_width=24, stroke_linecap='round'))
    b.append(Pa(dd('M', X0 + 40, Y0 + 210, 'q', -10, 80, 14, 170), stroke=Q['water'], stroke_width=14, stroke_linecap='round'))
    b.append(R(X0 - 6, Y0 + 190, 70, 34, '#A3ADB7', rx=10, stroke=O, stroke_width=5))
    b.append(img)
    b.append(gen.duck(X0 + W - 80, cy - 150, 1.3))
    b += [Ln(X0 + W - 200 - k * 30, cy - 166 + k * 18, X0 + W - 162 - k * 30, cy - 166 + k * 18, '#FFFFFF', 6, opacity='.8') for k in range(3)]
    return b


def sc2():
    b = room('tpB')
    cx, cy = X0 + W / 2, Y0 + H / 2
    b.append(G(R(cx + 150, cy - 250, 116, 136, '#FFFFFF', stroke=O, stroke_width=4) + T(cx + 208, cy - 166, '21', 58, '#C73E2E', weight='bold', anchor='middle')
               + Ln(cx + 164, cy - 232, cx + 252, cy - 132, screens2.INK, 5) + Ln(cx + 252, cy - 232, cx + 164, cy - 132, screens2.INK, 5), filter='url(#dsh)'))
    b.append(fx('toilet', False, X0 + 170, FL + 10, 290)[0])
    b.append(G(resident(cx + 70, cy + 70), filter='url(#dsh)'))
    b.append(gen.arrow(cx + 210, cy + 40, cx + 210, cy - 60, Q['cream'], 9) + gen.arrow(cx + 254, cy - 60, cx + 254, cy + 40, Q['cream'], 9))
    return b


def sc3():
    b = room('tpB')
    img, c, cy = fx('dryer', True, X0 + 230, FL - 40, 230)
    b.append(img)
    ry = cy + .18 * c * .97                        # перекладина z = -0.18
    b.append(R(X0 + 150 - 8, ry - 20, 16, 34, '#C49A5E', rx=4, stroke=O, stroke_width=4))
    b.append(sock(X0 + 150, ry + 10))
    px, py = X0 + 410, ry
    b.append(R(px - 8, py - 20, 16, 34, '#C49A5E', rx=4, stroke=O, stroke_width=4))
    ghost = dd('M', px - 14, py + 10, 'L', px - 14, py + 70, 'Q', px - 14, py + 90, px + 12, py + 90, 'L', px + 32, py + 90, 'Q', px + 44, py + 90, px + 44, py + 76,
               'Q', px + 44, py + 64, px + 24, py + 62, 'L', px + 14, py + 62, 'L', px + 14, py + 10, 'Z')
    b.append(Pa(ghost, 'none', stroke='#F4EEDC', stroke_width=5, stroke_dasharray='14 10', stroke_linejoin='round', opacity='.85'))
    b.append(cloud(px + 70, py + 30, 26))
    b += [spark(px + dx, py + dy, r) for dx, dy, r in ((120, -10, 14), (60, -40, 10), (126, 92, 9))]
    return b


def sc4():
    b = room('tpM')
    mx = X0 + W - 60
    img, c, cy = fx('washer', True, mx, FL + 6, 300, rot=9)
    b.append(Pa(dd('M', X0 - 10, FL - 120, 'L', mx - 150, FL - 128), stroke=O, stroke_width=22, stroke_linecap='round'))
    b.append(Pa(dd('M', X0 - 10, FL - 120, 'L', mx - 150, FL - 128), stroke='#DCE2E8', stroke_width=13, stroke_linecap='round'))
    b += [Ln(mx - 330 + k * 14, FL - 250 + k * 64, mx - 190 + k * 10, FL - 250 + k * 64, '#FFFFFF', 7, opacity='.75') for k in range(4)]
    for k in range(2):
        b.append(Ln(X0 + 60, FL + 18 + k * 30, mx - 120, FL + 18 + k * 30, '#3A3129', 9, stroke_dasharray='34 22'))
    b.append(E(X0 + 150, FL + 4, 90, 16, 'url(#waterG)', stroke=O, stroke_width=3, opacity='.9'))
    b += [C(X0 + 120 + dx, FL - 30 + dy, r, Q['water'], stroke=O, stroke_width=2) for dx, dy, r in ((0, 0, 9), (40, -22, 7), (78, 4, 6))]
    b.append(img)
    return b


def sc5():
    """Кв. 5 «Звено»: кран ожил — первым к воде успел кот; хозяин с зубной щёткой ждёт очереди."""
    b = room('tpB')
    img, c, cy = fx('sink', True, X0 + 200, FL + 6, 330)
    b.append(img)
    spout = X0 + 200 + .10 * c                # струя из гусака (модель: x 0.14, центр габарита 0.04)
    counter = cy - .02 * c                     # столешница мойки
    b.append(cat(spout + 52, counter + 4, .85, drink=True))
    sc_ = .92
    hip = FL - 172 * sc_
    b.append(G(figure(X0 + 460, hip, sc_, shirt='#E9E4D4', pants='#3D5A8E', hair='bald', mustache=True, arms=((-54, -10), (-40, -196)),
                      elbows=((-80, -70), (-90, -120)), look=(-1, .4), brows='flat', mouth='flat'), filter='url(#dsh)'))
    hx, hy = X0 + 460 - 40 * sc_, hip - 196 * sc_
    b.append(Ln(hx, hy, hx - 6, hy - 70, O, 12) + Ln(hx, hy, hx - 6, hy - 70, '#4FA3D9', 7))
    b.append(R(hx - 16, hy - 92, 22, 26, '#FFFFFF', rx=4, stroke=O, stroke_width=3))
    b.append(Ln(X0 + 400, Y0 + 130, X0 + 430, Y0 + 116, '#FFFFFF', 6, opacity='.7'))
    return b


def sc6():
    """Кв. 6 «Кругом!»: полотенцесушитель снова горячий — жилец после душа в халате и тюрбане обнимает его."""
    b = room('tpM')
    img, c, cy = fx('dryer', True, X0 + 200, FL - 90, 300)
    b.append(img)
    sc_ = .95
    hip = FL - 172 * sc_
    px = X0 + 380
    b.append(G(figure(px, hip, sc_, shirt='#7FB3D5', pants='#7FB3D5', hair='brown', arms=((-170, -150), (-150, -60)),
                      elbows=((-110, -170), (-100, -60)), look=(-1, 0), brows='up', mouth='smile', sleeves='#7FB3D5'), filter='url(#dsh)'))
    tx, ty = px, hip - 196 * sc_ - 40
    b.append(Pa(dd('M', tx - 46, ty + 14, 'Q', tx - 50, ty - 50, tx, ty - 48, 'Q', tx + 52, ty - 50, tx + 46, ty + 14, 'Q', tx, ty - 6, tx - 46, ty + 14, 'Z'),
                '#F2F2EC', stroke=O, stroke_width=5, stroke_linejoin='round'))
    b.append(Pa(dd('M', tx - 30, ty - 30, 'Q', tx, ty - 40, tx + 30, ty - 24), stroke='#C9CFC4', stroke_width=4))
    b.append(Ln(px - 50, hip + 6, px + 50, hip + 6, '#5E8FB3', 10))
    for k, (dx, dy) in enumerate(((-120, -330), (-60, -380), (-170, -400))):
        x, y = px + dx, hip + dy
        b.append(Pa(dd('M', x, y + 10, 'C', x - 22, y - 8, x - 10, y - 26, x, y - 12, 'C', x + 10, y - 26, x + 22, y - 8, x, y + 10, 'Z'), '#E2687A',
                    stroke=O, stroke_width=3, opacity='%.2f' % (.95 - k * .15)))
    return b


def sc7():
    b = room('tpY')
    img, c, cy = fx('sink', True, X0 + 250, FL + 6, 340)
    b.append(img)
    cx, top = X0 + 210, cy - .02 * c
    for k in range(9):
        b.append(E(cx + (k % 2) * 10, top - 20 - k * 28, 110, 20, 'url(#enam)', stroke=O, stroke_width=4))
    px, py = X0 + 470, Y0 + 260
    b.append(G(E(px, py, 80, 80, 'url(#enam)', stroke=O, stroke_width=5) + E(px, py, 48, 48, 'none', stroke='#D5DBE3', stroke_width=4), filter='url(#dsh)'))
    b += [spark(px + dx, py + dy, r) for dx, dy, r in ((60, -80, 18), (-60, -60, 11), (60, 80, 12))]
    return b


def sc8():
    """Кв. 8 «Гусеница»: колонка горит — в ванной пар, на запотевшем зеркале пальцем нарисовано сердечко."""
    b = room('tpB')
    img, c, cy = fx('heater', True, X0 + 150, Y0 + 420, 250)
    b.append(R(X0 + 150 - 14, Y0 + 410, 28, FL - Y0 - 410, '#8F98A1', stroke=O, stroke_width=4))
    b.append(img)
    mx, my = X0 + 420, Y0 + 230
    b.append(G(E(mx, my, 104, 130, '#C99A2E', stroke=O, stroke_width=5) + E(mx, my, 90, 116, '#DDE7EE', stroke=O, stroke_width=3), filter='url(#dsh)'))
    b.append(E(mx, my, 90, 116, '#FFFFFF', opacity='.55'))
    b.append(Pa(dd('M', mx, my + 30, 'C', mx - 60, my - 10, mx - 34, my - 64, mx, my - 30, 'C', mx + 34, my - 64, mx + 60, my - 10, mx, my + 30, 'Z'),
                'none', stroke='#9FB3C2', stroke_width=9, stroke_linejoin='round'))
    b += [Ln(mx + dx, my + 40, mx + dx, my + 40 + ln, '#9FB3C2', 4) for dx, ln in ((-8, 30), (14, 18))]
    b += [cloud(x, y, r, .7) for x, y, r in ((X0 + 120, Y0 + 90, 44), (X0 + 330, Y0 + 70, 38), (X0 + 520, Y0 + 400, 40), (X0 + 260, Y0 + 520, 36))]
    b.append(steam(X0 + 120, Y0 + 170, 3, 30, 50, .7))
    return b


def sc9():
    """Кв. 9 «Домкрат»: горячая вода — лысый жилец счастливо моет голову; пены больше, чем волос."""
    b = room('tpY')
    img, c, cy = fx('heater', True, X0 + 130, Y0 + 400, 230)
    b.append(R(X0 + 130 - 14, Y0 + 390, 28, FL - Y0 - 390, '#8F98A1', stroke=O, stroke_width=4))
    b.append(img)
    sc_ = 1.0
    px, hip = X0 + 390, FL - 172
    b.append(G(figure(px, hip, sc_, shirt='#F6F4EF', pants='#3D5A8E', hair='bald', mustache=True, arms=((-40, -262), (44, -262)),
                      elbows=((-100, -220), (100, -220)), look=(0, -1), brows='up', mouth='smile'), filter='url(#dsh)'))
    hy = hip - 196
    for dx, dy, r in ((-40, -40, 26), (-6, -60, 32), (32, -46, 28), (56, -20, 20), (-58, -12, 18), (12, -86, 22), (-30, -84, 18)):
        b.append(C(px + dx, hy + dy, r, '#FFFFFF', stroke=O, stroke_width=3))
    b += [C(px + dx, hy + dy, r, '#FFFFFF', stroke=O, stroke_width=2) for dx, dy, r in ((90, -110, 9), (-96, -130, 7), (60, -150, 6))]
    b.append(G(R(X0 + 480, FL - 60, 34, 60, '#2F8F4E', rx=8, stroke=O, stroke_width=4) + R(X0 + 487, FL - 76, 20, 18, '#F4EEDC', stroke=O, stroke_width=3),
               filter='url(#dsh)'))
    return b


def sc10():
    b = room('tpY')
    hx, hy = X0 + 150, Y0 + 250
    img, c, cy = fx('heater', True, hx, hy + 150, 270)
    b.append(R(hx - 16, hy + 140, 32, FL - hy - 140, '#8F98A1', stroke=O, stroke_width=4))
    b.append(img)
    b.append(E(hx, hy - 60, 170, 170, 'url(#lamp)'))
    b += [Pa(dd('M', hx + 150 + k * 26, hy - 20 - k * 30, 'q', -18, -22, 0, -44, 't', 0, -44), stroke='#FFFFFF', stroke_width=6, stroke_linecap='round', opacity='.55') for k in range(2)]
    b.append(G(resident6(X0 + 372, FL - 172), filter='url(#dsh)'))
    return b


SCENES = {1: sc1, 2: sc2, 3: sc3, 4: sc4, 5: sc5, 6: sc6, 7: sc7, 8: sc8, 9: sc9, 10: sc10}
IDS = [int(a) for a in sys.argv[1:] if a.isdigit()] or list(SCENES)
os.makedirs(TMP, exist_ok=True)
for i in IDS:
    body = ''.join(SCENES[i]())
    clip = '<clipPath id="cs"><rect x="%d" y="%d" width="%d" height="%d" rx="16"/></clipPath>' % (X0, Y0, W, H)
    svg = os.path.join(TMP, 'scene%d.svg' % i)
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="588" height="648" viewBox="0 0 588 648">'
                '<defs>%s%s%s</defs>%s%s</svg>' % (gen.DEFS, BASE, clip, G(body, clip_path='url(#cs)'),
                                                 R(X0, Y0, W, H, 'none', rx=16, stroke='#C99A2E', stroke_width=4)))
    subprocess.run(['rsvg-convert', '-w', '588', '-h', '648', '-o', os.path.join(OUT, 'scene%d.png' % i), svg], check=True)
    print('scene%d' % i)
