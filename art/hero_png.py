#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/hero_png.py — Лапидус для карточек и экранов, нарисованный самим движком (love . --hero): гофра — текстура из Blender,
ноги — Blender, голова — прежний рисунок. Возвращает SVG <image> (PNG встроен, кэш в build/hero).
Подключение: art/screens2.py заменяет им gen2.hero."""
import base64, hashlib, os, subprocess
import gen2

ROOT = gen2.ROOT
CACHE = os.path.join(ROOT, 'build', 'hero')
os.makedirs(CACHE, exist_ok=True)


def hero_img(pts, c, Lmin, Lmax, active='head', screwed=(False, False), ring=True, wet=False):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    pad = 1.0 * c
    ox, oy = int(min(xs) - pad), int(min(ys) - pad)
    w, h = int(max(xs) + pad) - ox, int(max(ys) + pad) - oy
    job = ('{ out = %r, w = %d, h = %d, ox = %d, oy = %d, c = %r, Lmin = %d, Lmax = %d, pts = { %s }, active = %s, wet = %s, sh = %s, sf = %s, ring = %s }'
           % (None, w, h, ox, oy, float(c), Lmin, Lmax, ', '.join('{ %r, %r }' % (float(x), float(y)) for x, y in pts),
              '"%s"' % active if active else 'nil', str(bool(wet)).lower(), str(bool(screwed[1])).lower(), str(bool(screwed[0])).lower(),
              str(bool(ring)).lower()))
    key = hashlib.sha1((job + str(os.path.getmtime(os.path.join(ROOT, 'game', 'board.lua')))).encode()).hexdigest()[:16]
    png = os.path.join(CACHE, key + '.png')
    if not os.path.exists(png):
        lua = os.path.join(CACHE, key + '.lua')
        with open(lua, 'w') as f:
            f.write('return { %s }\n' % job.replace('out = None', 'out = %r' % png).replace("'", '"'))
        subprocess.run(['xvfb-run', '-a', '-s', '-screen 0 1920x1080x24', 'love', '.', '--hero', lua], cwd=ROOT, check=True,
                       env=dict(os.environ, ALSOFT_DRIVERS='null'), capture_output=True)
    data = base64.b64encode(open(png, 'rb').read()).decode()
    return '<image x="%d" y="%d" width="%d" height="%d" xlink:href="data:image/png;base64,%s"/>' % (ox, oy, w, h, data)


GFX = os.path.join(ROOT, 'assets', 'gfx')
ANG = {'right': 0, 'down': 90, 'left': 180, 'up': -90}
SIG = {'up': 'u', 'right': 'r', 'down': 'd', 'left': 'l'}
_B64 = {}
FX_CARD = True   # приборы на карточках — крупно, у стыка; в окнах дома — в клетку


def sprite_img(name, cx, cy, c, rot=0, flip=False):
    """Игровой спрайт (холст 480 = 2 клетки, центр — центр клетки) в SVG: клетка c px, поворот, отражение."""
    path = os.path.join(GFX, name + '.png')
    if not os.path.exists(path) and name.startswith('fit_'):   # деталь только для карточек — дорендерить в Blender
        subprocess.run(['xvfb-run', '-a', 'blender', '-b', '-P', os.path.join(ROOT, 'art', 'blender', 'fittings.py'), '--', GFX, name],
                       check=True, capture_output=True)
    if name not in _B64:
        _B64[name] = base64.b64encode(open(os.path.join(GFX, name + '.png'), 'rb').read()).decode()
    tr = 'translate(%.2f %.2f) rotate(%d) scale(%s 1)' % (cx, cy, rot, -1 if flip else 1)
    return '<g transform="%s"><image x="%.2f" y="%.2f" width="%.2f" height="%.2f" xlink:href="data:image/png;base64,%s"/></g>' % (
        tr, -c, -c, 2 * c, 2 * c, _B64[name])


def fitting_img(cx, cy, c, ports):
    sig = ''.join(SIG[d] + ports[d] for d in ('up', 'right', 'down', 'left') if d in ports)
    return sprite_img('fit_' + sig, cx, cy, c)


def port_img(cx, cy, c, dr, th, fixed=False):
    return sprite_img('port_%s_fx' % th, cx, cy, c, ANG[dr])  # стык стандарта (сталь, Blender) — и для схем «Н + В»


def fixture_img(what):
    def f(cx, cy, c, wet=False, *a, **k):
        # как в игре у стены: прибор крупнее клетки и отодвинут от стыка (вход слева)
        if not FX_CARD:
            return sprite_img('fx_%s_%s' % (what, 'wet' if wet else 'dry'), cx, cy, c * 1.15)
        return sprite_img('fx_%s_%s' % (what, 'wet' if wet else 'dry'), cx + .42 * c, cy - .08 * c, c * 1.45)
    return f


def heel_img(pt, dr, c, active, screwed):
    return sprite_img('feet_%s_%s' % (dr, 'on' if active else 'off'), pt[0], pt[1], c)


def use_in(mod):
    """Подменить в модуле экранов векторные детали на игровые спрайты (Blender) и Лапидуса — на рисунок движка."""
    mod.hero = hero_img
    mod.fitting2 = fitting_img
    mod.port2 = port_img
    mod.heelL = heel_img
    for what in ('bath', 'toilet', 'sink'):
        setattr(mod, what + '2', fixture_img(what))
    g = getattr(mod, 'gen2')
    for what in ('washer', 'dryer', 'heater'):
        setattr(g, what + '2', fixture_img(what))
    mod.porcelain2 = lambda x, y, c: sprite_img('porcelain', x, y, c)
