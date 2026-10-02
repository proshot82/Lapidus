#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/parts.py — латунные фитинги, слив-трап и выходы сети в пропорциях настоящих деталей (03.10.2026, замечание Lao:
«детали громоздкие, не похожи на настоящие, залезают на соседние клетки»).

Сверено с фото (Wikimedia Commons: PexMall brass fittings; Drain cover with trap; -42 drain):
- муфта — короткий гладкий цилиндр с внутренней резьбой с обоих концов, по краям — буртики;
- ниппель — шестигранник посередине и наружная резьба по обе стороны, резьба тоньше шестигранника;
- угольник и тройник — литое тело со скруглённым углом, на выходах — раструбы с внутренней резьбой;
- заглушка — пробка: шестигранная головка и резьбовой хвостовик (Н) или колпачок с шестигранником (В);
- напольный трап — квадратный фланец вровень с плиткой, воронка, под ней узкий отвод и гидрозатвор.
Всё, что рисуется для клетки, лежит внутри квадрата ±0.47 клетки: детали больше не залезают на стены и соседей."""
import math
from gen import n, R, C, E, Ln, Pg, Pa, G, dd

OL = '#2B2118'
LIM = .47          # граница рисования от центра клетки (доля клетки)
D_BODY = .30       # диаметр тела детали
D_SOCK = .38       # диаметр раструба с внутренней резьбой
D_THR = .24        # диаметр наружной резьбы
D_HEX = .40        # «под ключ»


def orient(body, dr, cx, cy):
    if dr == 'right':
        return body
    if dr == 'left':
        return '<g transform="translate(%s 0) scale(-1 1)">%s</g>' % (n(2 * cx), body)
    return '<g transform="rotate(%d %s %s)">%s</g>' % (-90 if dr == 'up' else 90, n(cx), n(cy), body)


def pal(fixed):
    """Латунь (подвижное) или сталь (сеть, окаменевшее) — язык материалов §8."""
    if fixed:
        return dict(body='url(#cylGd)', hex='url(#nutGd)', dk='#2F353B', hl='#EEF2F6', mid='#7C868F', bore='#14181B')
    return dict(body='url(#cylG)', hex='url(#nutG)', dk='#5E4410', hl='#FFF1C2', mid='#A27C25', bore='#1E150B')


def male(cx, cy, c, x0, fixed=False):
    """Наружная резьба вправо от x0 до границы: хвостовик тоньше тела, косые витки, фаска на торце."""
    p, lw = pal(fixed), c * .03
    x1, h = cx + LIM * c, D_THR * c / 2
    s = [Pg([(x0, cy - h), (x1 - .035 * c, cy - h), (x1, cy - h + .035 * c), (x1, cy + h - .035 * c), (x1 - .035 * c, cy + h), (x0, cy + h)],
            p['body'], stroke=OL, stroke_width=lw, stroke_linejoin='round')]
    k, x = 0, x0 + .035 * c
    while x < x1 - .05 * c:
        s.append(Ln(x, cy - h + .01 * c, x + .025 * c, cy + h - .01 * c, p['dk'], c * .016, opacity='.75'))
        s.append(Ln(x + .012 * c, cy - h + .02 * c, x + .03 * c, cy + .02 * c, p['hl'], c * .008, opacity='.8'))
        x += .042 * c
        k += 1
    return ''.join(s)


def female(cx, cy, c, x0, fixed=False):
    """Раструб с внутренней резьбой: шире тела, буртик на торце, в торце виден тёмный вход с витками."""
    p, lw = pal(fixed), c * .03
    x1, h = cx + LIM * c, D_SOCK * c / 2
    s = [R(x0, cy - h, x1 - x0, 2 * h, p['body'], rx=.03 * c, stroke=OL, stroke_width=lw),
         R(x1 - .06 * c, cy - h - .005 * c, .06 * c, 2 * h + .01 * c, p['hex'], rx=.02 * c, stroke=OL, stroke_width=lw * .8),
         E(x1 - .03 * c, cy, .022 * c, h * .62, p['bore'], stroke=OL, stroke_width=c * .012)]
    for k in (-.07, -.02, .03):
        s.append(Ln(x1 - .04 * c, cy + k * c, x1 - .02 * c, cy + k * c + .02 * c, p['mid'], c * .01))
    s.append(Ln(x0 + .02 * c, cy - h + .035 * c, x1 - .08 * c, cy - h + .035 * c, p['hl'], c * .014, opacity='.7'))
    return ''.join(s)


def port(cx, cy, c, dr, th, fixed=False, x0=None):
    """Выход вправо от центра (поворачивается orient): резьба Н или В у границы клетки."""
    x0 = cx + (x0 if x0 is not None else (.22 if th == 'N' else .26)) * c
    return orient(male(cx, cy, c, x0, fixed) if th == 'N' else female(cx, cy, c, x0, fixed), dr, cx, cy)


def hexblock(cx, cy, c, fixed=False, w=.22):
    """Шестигранник «под ключ» вбок: три видимые грани."""
    p, h = pal(fixed), D_HEX * c / 2
    s = [R(cx - w * c / 2, cy - h, w * c, 2 * h, p['hex'], rx=.015 * c, stroke=OL, stroke_width=c * .03)]
    for k in (-.5, .5):
        s.append(Ln(cx - w * c / 2 + .015 * c, cy + k * h, cx + w * c / 2 - .015 * c, cy + k * h, p['dk'], c * .012, opacity='.6'))
    s.append(Ln(cx - w * c / 2 + .03 * c, cy - h * .78, cx + w * c / 2 - .03 * c, cy - h * .78, p['hl'], c * .014, opacity='.8'))
    return ''.join(s)


def arm(cx, cy, c, dr, x1, fixed=False):
    """Гладкое тело от центра до x1 (доля клетки) в сторону dr."""
    p, h = pal(fixed), D_BODY * c / 2
    s = (R(cx, cy - h, x1 * c, 2 * h, p['body'], stroke=OL, stroke_width=c * .03)
         + Ln(cx + .02 * c, cy - h * .55, cx + x1 * c - .01 * c, cy - h * .55, p['hl'], c * .016, opacity='.6'))
    return orient(s, dr, cx, cy)


OPP = {'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}


def elbow(cx, cy, c, ds, fixed=False):
    """Колено: канонически выходы вправо и вверх, внешний угол (слева снизу) скруглён; остальные пары — отражением."""
    p, h, L = pal(fixed), D_BODY * c / 2, .30 * c
    r = 1.7 * h
    d = dd('M', cx + L, cy - h, 'L', cx + h + .02 * c, cy - h, 'Q', cx + h, cy - h, cx + h, cy - h - .02 * c, 'L', cx + h, cy - L,
           'L', cx - h, cy - L, 'L', cx - h, cy + h - r, 'A', r, r, 0, 0, 0, cx - h + r, cy + h, 'L', cx + L, cy + h, 'Z')
    body = (Pa(d, p['body'], stroke=OL, stroke_width=c * .03, stroke_linejoin='round')
            + Pa(dd('M', cx - h * .55, cy - L + .02 * c, 'L', cx - h * .55, cy + h - r * .8, 'A', r * .6, r * .6, 0, 0, 0, cx - h * .55 + r * .5, cy + h * .45),
                 stroke=p['hl'], stroke_width=c * .016, opacity='.6', stroke_linecap='round'))
    sx = 1 if 'right' in ds else -1
    sy = 1 if 'up' in ds else -1
    if sx == 1 and sy == 1:
        return body
    return '<g transform="translate(%s %s) scale(%d %d)">%s</g>' % (n(cx - sx * cx), n(cy - sy * cy), sx, sy, body)


def fitting(cx, cy, c, ports, fixed=False):
    """Подвижная деталь (или окаменевшая — fixed) по набору выходов {dr: 'N'|'V'}."""
    ds = list(ports)
    p = pal(fixed)
    s = []
    if len(ds) == 1:                       # заглушка
        dr, th = ds[0], ports[ds[0]]
        if th == 'N':                      # пробка: шестигранная головка + хвостовик
            s.append(orient(hexblock(cx - .02 * c, cy, c, fixed, .24) + male(cx, cy, c, cx + .10 * c, fixed), dr, cx, cy))
        else:                              # колпачок: глухое донце, шестигранник, раструб
            body = (R(cx - .16 * c, cy - D_SOCK * c / 2, .22 * c, D_SOCK * c, p['body'], rx=.08 * c, stroke=OL, stroke_width=c * .03)
                    + hexblock(cx + .06 * c, cy, c, fixed, .14) + female(cx, cy, c, cx + .13 * c, fixed))
            s.append(orient(body, dr, cx, cy))
        return ''.join(s)
    straight = len(ds) == 2 and OPP[ds[0]] == ds[1]
    if straight:
        a, b = ds
        ta, tb = ports[a], ports[b]
        if ta == 'V' and tb == 'V':        # муфта: гладкий цилиндр, раструбы на концах
            s.append(arm(cx, cy, c, a, .30, fixed) + arm(cx, cy, c, b, .30, fixed))
            s.append(port(cx, cy, c, a, 'V', fixed, .24) + port(cx, cy, c, b, 'V', fixed, .24))
            return ''.join(s)
        # ниппель (Н–Н) и переходник (В–Н): шестигранник посередине
        for dr in (a, b):
            s.append(port(cx, cy, c, dr, ports[dr], fixed, .10 if ports[dr] == 'N' else .14))
        s.append(orient(hexblock(cx, cy, c, fixed, .22), a if a in ('left', 'right') else 'right', cx, cy) if a in ('left', 'right')
                 else orient(hexblock(cx, cy, c, fixed, .22), 'up', cx, cy))
        return ''.join(s)
    # угольник: литой гнутый корпус со скруглённым внешним углом (как у настоящего колена)
    if len(ds) == 2:
        s.append(elbow(cx, cy, c, ds, fixed))
    else:                                  # тройник, крестовина: сквозная труба + отвод с приливом
        pair = next(((a, OPP[a]) for a in ds if OPP[a] in ds), None)
        for dr in ds:
            if not pair or dr not in pair:
                s.append(arm(cx, cy, c, dr, .30, fixed))
        if pair:
            s.append(arm(cx, cy, c, pair[0], .30, fixed) + arm(cx, cy, c, pair[1], .30, fixed))
        s.append(C(cx, cy, D_BODY * c / 2 + .02 * c, p['body'], stroke=OL, stroke_width=c * .03))
        s.append(E(cx - .04 * c, cy - .05 * c, .05 * c, .03 * c, p['hl'], opacity='.75'))
    for dr in ds:
        s.append(port(cx, cy, c, dr, ports[dr], fixed))
    return ''.join(s)


def drain(cx, cy, c, bottom=1100, left=False, right=False, pipe=True, flap=True):
    """Напольный трап в разрезе, решётку сняли (поэтому всё, что упало, смывает): стальной фланец вровень с плиткой,
    воронка, узкий отвод вниз и тёмный гидрозатвор. Несколько сливов подряд — один линейный трап (лоток вдоль стены
    душевой): у соседей фланец и лоток сплошные, отвод и откинутая решётка — по одному на весь лоток.
    Всё в пределах своих клеток; отвод уходит в плиту пола (bottom)."""
    s, top, x0 = [], cy - c / 2, cx - c / 2
    s.append(R(x0, top, c, bottom - top, 'url(#pitG)'))
    if pipe:
        s.append(R(cx - .17 * c, cy + .10 * c, .34 * c, bottom - cy - .10 * c, 'url(#ironV)', stroke=OL, stroke_width=c * .025))
        s.append(R(cx - .20 * c, cy + .30 * c, .40 * c, .08 * c, 'url(#ironH)', rx=.02 * c, stroke=OL, stroke_width=c * .02))
    lx = x0 if left else x0 + .06 * c          # верх лотка: у соседа — до края клетки
    rx = x0 + c if right else x0 + c - .06 * c
    blx = x0 if left else (cx - .16 * c if pipe else x0 + .22 * c)
    brx = x0 + c if right else (cx + .16 * c if pipe else x0 + c - .22 * c)
    by = cy + .14 * c
    s.append(Pg([(lx, top + .06 * c), (rx, top + .06 * c), (brx, by), (blx, by)], 'url(#steelG)'))
    s.append(Ln(blx, by, brx, by, OL, c * .03))
    if not left:
        s.append(Ln(lx, top + .06 * c, blx, by, OL, c * .03))
    if not right:
        s.append(Ln(rx, top + .06 * c, brx, by, OL, c * .03))
    s.append(Pg([(lx + (0 if left else .10 * c), top + .09 * c), (rx - (0 if right else .10 * c), top + .09 * c),
                 (brx - (0 if right else .07 * c), by - .03 * c), (blx + (0 if left else .07 * c), by - .03 * c)], '#1B2A31'))
    if pipe:
        s.append(E(cx, cy + .02 * c, .17 * c, .035 * c, 'url(#waterG)', opacity='.9'))
        s.append(E(cx - .05 * c, cy + .01 * c, .05 * c, .012 * c, '#E8FAFF', opacity='.8'))
    else:
        s.append(R(blx + (0 if left else .07 * c), by - .08 * c, brx - blx - (0 if left else .07 * c) - (0 if right else .07 * c), .05 * c, 'url(#waterG)', opacity='.8'))
    fx0, fx1 = x0 + (0 if left else .01 * c), x0 + c - (0 if right else .01 * c)
    s.append(R(fx0, top, fx1 - fx0, .07 * c, 'url(#steelG)'))
    s.append(Ln(fx0, top, fx1, top, OL, c * .025) + Ln(fx0, top + .07 * c, fx1, top + .07 * c, OL, c * .025))
    if not left:
        s.append(Ln(fx0, top, fx0, top + .07 * c, OL, c * .025))
    if not right:
        s.append(Ln(fx1, top, fx1, top + .07 * c, OL, c * .025))
    if not left:
        s.append(C(x0 + .08 * c, top + .035 * c, .014 * c, '#6E7781'))
    if not right:
        s.append(C(x0 + .92 * c, top + .035 * c, .014 * c, '#6E7781'))
    if flap:
        # решётка откинута на петле у правого края (как откинутые крышки трапов на фото)
        hx, hy, gw, gh = x0 + c - .06 * c, top + .005 * c, .34 * c, .30 * c
        tilt = .10 * c
        quad = [(hx, hy), (hx - tilt, hy - gh), (hx - tilt - gw * .55, hy - gh - .03 * c), (hx - gw * .55, hy)]
        s.append(Pg(quad, 'url(#steelG)', stroke=OL, stroke_width=c * .022, stroke_linejoin='round'))
        for i in range(3):
            for j in range(4):
                u, v = (i + .7) / 3.6, (j + .6) / 4.4
                s.append(C(hx - gw * .55 * u - tilt * v, hy - gh * v - .03 * c * u, .016 * c, '#3E454C'))
        s.append(C(hx - .01 * c, hy, .022 * c, '#8F98A1', stroke=OL, stroke_width=c * .012))
    return ''.join(s)


def fountain(cx, cy, c):
    """Фонтанчик из открытой резьбы вверх (образец Lao 03.10; первая попытка с лепестками — «угловатый цветок»).
    Классическая форма фонтана с иконок: столбик воды, сверху гладкий водяной купол-зонтик, его края стекают вниз и
    кончаются округлыми каплями. Только плавные кривые, обводка тёмно-синяя. (cx, cy) — торец резьбы."""
    DK, W1, W2, W3 = '#0F4E78', '#1E8DCB', '#45BDF0', '#D2F5FF'
    sw = .024 * c
    s = []
    top = cy - .62 * c                     # макушка купола
    ry = cy - .40 * c                      # уровень края купола
    # прозрачная водяная завеса под куполом (купол «полный», а не пустой зонтик)
    s.append(Pa(dd('M', cx - .40 * c, cy - .16 * c, 'C', cx - .40 * c, ry - .10 * c, cx - .22 * c, top, cx, top,
                   'C', cx + .22 * c, top, cx + .40 * c, ry - .10 * c, cx + .40 * c, cy - .16 * c, 'Z'), W2, opacity='.35'))
    for x in (-.30, -.18, .18, .30):
        s.append(Ln(cx + x * c, ry - .02 * c, cx + x * 1.08 * c, cy - .14 * c, W3, .014 * c, opacity='.55'))
    # столбик
    s.append(R(cx - .055 * c, top + .06 * c, .11 * c, cy - top - .05 * c, W1, rx=.05 * c, stroke=DK, stroke_width=sw))
    s.append(R(cx - .03 * c, top + .14 * c, .022 * c, cy - top - .20 * c, W3, rx=.011 * c, opacity='.8'))

    def shell(ro, ri, drop_y, fill, edge):
        # оболочка купола: внешняя кривая (ro — полуширина), внутренняя (ri), края стекают до drop_y
        d = dd('M', cx - ro, drop_y,
               'C', cx - ro, ry - .10 * c, cx - ro * .55, top, cx, top,
               'C', cx + ro * .55, top, cx + ro, ry - .10 * c, cx + ro, drop_y,
               'L', cx + ri, drop_y,
               'C', cx + ri, ry - .02 * c, cx + ri * .5, top + .09 * c, cx, top + .09 * c,
               'C', cx - ri * .5, top + .09 * c, cx - ri, ry - .02 * c, cx - ri, drop_y, 'Z')
        return Pa(d, fill, stroke=edge, stroke_width=sw, stroke_linejoin='round')
    s.append(shell(.42 * c, .30 * c, cy - .18 * c, W1, DK))          # задний, шире и длиннее
    s.append(shell(.34 * c, .22 * c, cy - .26 * c, W2, DK))          # передний
    # капли на концах струй (округлые «бусины»)
    for x, y, r, col in ((-.36, -.18, .068, W1), (.36, -.18, .068, W1), (-.28, -.26, .062, W2), (.28, -.26, .062, W2)):
        s.append(C(cx + x * c, cy + y * c, r * c, col, stroke=DK, stroke_width=sw))
        s.append(C(cx + x * c - .018 * c, cy + y * c - .018 * c, .016 * c, '#FFFFFF', opacity='.85'))
    # блики по куполу и брызги над ним
    s.append(Pa(dd('M', cx - .22 * c, ry - .06 * c, 'C', cx - .18 * c, top + .05 * c, cx - .08 * c, top + .03 * c, cx - .02 * c, top + .03 * c),
                stroke=W3, stroke_width=.03 * c, stroke_linecap='round', opacity='.85'))
    for x, y, r in ((-.10, -.70, .025), (.06, -.73, .02), (.16, -.67, .018)):
        s.append(C(cx + x * c, cy + y * c, r * c, W2, stroke=DK, stroke_width=sw * .6))
    return ''.join(s)


def fountain_puff(cx, cy, c):
    """Вариант Б фонтанчика: столбик и пышная «облачная» шапка из круглых клубов с фестончатым краем
    (ближе к образцу Lao по силуэту), без острых углов."""
    DK, W1, W2, W3 = '#0F4E78', '#1E8DCB', '#45BDF0', '#D2F5FF'
    sw = .024 * c
    s = []
    hy = cy - .52 * c
    s.append(R(cx - .055 * c, hy, .11 * c, cy - hy + .01 * c, W1, rx=.05 * c, stroke=DK, stroke_width=sw))
    back = [(-.30, .06, .085), (-.18, .10, .09), (-.06, .12, .09), (.06, .12, .09), (.18, .10, .09), (.30, .06, .085)]
    top = [(-.22, -.05, .10), (-.08, -.10, .11), (.08, -.10, .11), (.22, -.05, .10), (0, -.02, .12)]
    for x, y, r in back:                   # свисающие клубы (фестон снизу)
        s.append(C(cx + x * c, hy + y * c, r * c, W1, stroke=DK, stroke_width=sw))
    for x, y, r in top:                    # обводка верхних клубов
        s.append(C(cx + x * c, hy + y * c, r * c + sw / 2, DK))
    for x, y, r in back:
        s.append(C(cx + x * c, hy + y * c, r * c - sw / 2, W1))
    for x, y, r in top:
        s.append(C(cx + x * c, hy + y * c, r * c - sw / 2, W2))
    for x, y, r in top[:4]:
        s.append(E(cx + (x - .03) * c, hy + (y - .04) * c, r * .38 * c, r * .2 * c, W3, opacity='.85'))
    return ''.join(s)
