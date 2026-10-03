#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/fx_compose.py — приборы из рендера Blender (art/blender/fixtures.py) + слой лиц и эффектов (SVG) → assets/gfx/fx_*.png
и габариты game/fx_sizes.lua. Прибор вписывается в 0.80×0.92 клетки по габариту сухого корпуса (без пара и сосулек),
мокрый вариант — тем же преобразованием, чтобы спрайт не прыгал.
   xvfb-run -a blender -b -P art/blender/fixtures.py -- build/fx3d && python3 art/fx_compose.py build/fx3d"""
import json, math, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2
from gen import C, E, Ln, Pa, dd
from gen2 import Q, face2, defs2

ROOT = gen2.ROOT
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'build', 'fx3d')
OUT = os.environ.get('FX_OUT') or os.path.join(ROOT, 'assets', 'gfx')  # FX_OUT — крупные для сцен, без fx_sizes
DEFS = gen.DEFS + defs2(120, 0, 0, 'mint')
RES = int(os.environ.get('FX_RES', '480'))
CELL = RES // 2                  # px на клетку и в рендере, и в спрайтах (холст RES = 2 клетки)
SW, SH = .80, .92
AN = json.load(open(os.path.join(SRC, 'anchors.json')))
o = Q['ol']


def steam(x, y, c, n=3, w=.40):
    s = []
    for k in range(n):
        x0 = x + (-w / 2 + w * k / max(1, n - 1)) * c
        s.append(Pa(dd('M', x0, y, 'q', -.05 * c, -.07 * c, 0, -.14 * c, 't', 0, -.14 * c), stroke='#FFFFFF', stroke_width=c * .03,
                    stroke_linecap='round', opacity='%.2f' % (.85 - k * .12)))
    return ''.join(s)


def icicle(x, y, c, ln):
    return Pa(dd('M', x - .028 * c, y, 'L', x, y + ln * c, 'L', x + .028 * c, y, 'Z'), '#E6F7FF', stroke=o, stroke_width=c * .015, stroke_linejoin='round')


def eyes(x, y, c, wet, sz=.05, gap=.13):
    s = []
    for sx in (-1, 1):
        ex = x + sx * gap * c
        if wet:
            s.append(Pa(dd('M', ex - sz * c, y + .01 * c, 'Q', ex, y - 1.2 * sz * c, ex + sz * c, y + .01 * c), stroke=o, stroke_width=c * .03, stroke_linecap='round'))
        else:
            s.append(E(ex, y, sz * c, 1.1 * sz * c, '#FFFFFF', stroke=o, stroke_width=c * .025))
            s.append(C(ex - .012 * c, y + .01 * c, .5 * sz * c, o))
            s.append(Ln(ex + sx * 1.2 * sz * c, y - 1.7 * sz * c, ex - sx * .8 * sz * c, y - 1.2 * sz * c, o, c * .03))
    return ''.join(s)


def overlay(what, wet, a):
    c, s = CELL, []
    mood = 'happy' if wet else 'grumpy'
    if what == 'bath':
        s.append(face2(*a['face'], c * .78, mood, look=(-1, 0)))
    elif what == 'toilet':
        s.append(face2(*a['face'], c * .62, mood, look=(-1, 0)))
        if wet:
            x, y = a['wave']
            s.append(Pa(dd('M', x - .16 * c, y - .02 * c, 'q', .08 * c, -.10 * c, .16 * c, 0, 't', .16 * c, 0), stroke=Q['water'], stroke_width=c * .04, stroke_linecap='round'))
    elif what == 'sink':
        s.append(face2(*a['face'], c * .62, mood, look=(-1, 0)))
        if wet:
            (x0, y0), (x1, y1) = a['spout'], a['basin']
            s.append(Ln(x0, y0, x1, y1, Q['water'], c * .045))
            s.append(Ln(x0, y0, x1, y1, '#BDF3FF', c * .014))
    elif what == 'washer':
        x, y = a['eyes']
        s.append(eyes(x, y, c, wet, sz=.05, gap=.13))
        px, py = a['port']
        if wet:
            s.append(Pa(dd('M', px - .19 * c, py, 'q', .095 * c, -.07 * c, .19 * c, 0, 't', .19 * c, 0), stroke='#FFFFFF', stroke_width=c * .03, stroke_linecap='round'))
            s += [C(px + dx * c, py + dy * c, r * c, '#FFFFFF', opacity='.9') for dx, dy, r in ((-.06, .08, .03), (.07, .11, .025), (.02, -.07, .02))]
        else:
            s.append(E(px - .08 * c, py - .08 * c, .06 * c, .03 * c, '#FFFFFF', opacity='.35', transform='rotate(-35 %.1f %.1f)' % (px - .08 * c, py - .08 * c)))
    elif what == 'dryer':
        (x0, y0), (x1, y1) = a['st1'], a['st2']
        for dy in (0, .05 * c):                                          # полоски на полотенце
            s.append(Ln(x0 + .012 * c, y0 + dy, x1 - .012 * c, y1 + dy, '#E9F4FA', c * .022))
        s.append(face2(*a['face'], c * .56, mood, look=(-1, 0)))
        if wet:
            x, y = a['top']
            s.append(steam(x, y - .04 * c, c, 3, .36))
    elif what == 'heater':
        x, y = a['eyes']
        s.append(eyes(x, y, c, wet, sz=.055, gap=.12))
        wx, wy = a['mouth']
        wr = .10 * c
        if wet:
            s.append(C(wx, wy + .02 * c, wr * .95, 'url(#glow)'))
            for dx, hgt, col in ((-.05, .11, '#2E7BF1'), (.05, .11, '#2E7BF1'), (0, .16, '#3FA2FF')):
                fx0, fb = wx + dx * c, wy + .07 * c
                s.append(Pa(dd('M', fx0 - .03 * c, fb, 'Q', fx0 - .025 * c, fb - hgt * .55 * c, fx0, fb - hgt * c, 'Q', fx0 + .025 * c, fb - hgt * .55 * c, fx0 + .03 * c, fb, 'Z'),
                            col, stroke='#0E2E6B', stroke_width=c * .008))
            lx, ly = a['lamp']
            s.append(C(lx, ly, .025 * c, '#E0452F', stroke=o, stroke_width=c * .012))
            tx, ty = a['top']
            s.append(steam(tx, ty - .03 * c, c, 3, .30))
        else:
            for k in range(6):
                ang = k * math.pi / 3 + .3
                s.append(Ln(wx + math.cos(ang) * wr * .5, wy + math.sin(ang) * wr * .5, wx + math.cos(ang) * wr * .92, wy + math.sin(ang) * wr * .92, '#DDF3FF', c * .014, opacity='.85'))
            bx, by = a['bottom']
            for dx, ln in ((-.20, .12), (-.12, .08), (.02, .10)):
                s.append(icicle(bx + dx * c, by - .01 * c, c, ln))
            sx, sy = a['spout']
            s.append(icicle(sx, sy - .01 * c, c, .10))
    return ''.join(s)


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def bbox(png):
    w, h, x, y = map(int, run('convert', png, '-alpha', 'extract', '-threshold', '10%', '-trim', '-format', '%w %h %X %Y', 'info:').replace('+', ' ').split())
    return w, h, x, y


sizes = {}
tmp = os.path.join(SRC, '_tmp')
os.makedirs(tmp, exist_ok=True)
for what in ('bath', 'toilet', 'sink', 'washer', 'dryer', 'heater'):
    if 'dry' not in [k.split('_')[1] for k in AN if k.startswith(what + '_')]:
        continue
    w, h, x, y = bbox(os.path.join(SRC, what + '_dry.png'))
    k = min(SW * CELL / w, SH * CELL / h)
    cx, cy = x + w / 2, y + h / 2
    sizes[what] = (w * k / CELL, h * k / CELL)
    for wet in (False, True):
        key = '%s_%s' % (what, 'wet' if wet else 'dry')
        svg = os.path.join(tmp, key + '.svg')
        with open(svg, 'w', encoding='utf-8') as f:
            f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d"><defs>%s</defs>%s</svg>'
                    % (RES, RES, DEFS, overlay(what, wet, AN[key])))
        ov = os.path.join(tmp, key + '_ov.png')
        run('rsvg-convert', '-w', str(RES), '-h', str(RES), '-o', ov, svg)
        comp = os.path.join(tmp, key + '_c.png')
        run('convert', os.path.join(SRC, key + '.png'), ov, '-composite', comp)
        # вписать: масштаб k вокруг центра габарита сухого корпуса → центр холста; затем тень, как у латуни
        dst = os.path.join(OUT, 'fx_' + key + '.png')
        run('convert', comp, '-background', 'none', '-virtual-pixel', 'transparent', '-distort', 'SRT',
            '%.2f,%.2f %.5f 0 %d,%d' % (cx, cy, k, CELL, CELL), '+repage', fit := os.path.join(tmp, key + '_f.png'))
        run('convert', fit, '(', '+clone', '-fill', 'black', '-colorize', '100', '-channel', 'A', '-evaluate', 'multiply', '.45', '+channel',
            '-blur', '0x%d' % (5 * RES // 480), '-roll', '+%d+%d' % (5 * RES // 480, 8 * RES // 480), ')', '+swap', '-background', 'none', '-composite', dst)
        print('fx_' + key, 'k=%.3f' % k)
with open(os.path.join(ROOT, 'game', 'fx_sizes.lua') if not os.environ.get('FX_OUT') else os.devnull, 'w', encoding='utf-8') as f:
    f.write('-- Сгенерировано art/fx_compose.py: габариты спрайтов приборов (ширина, высота) в долях клетки.\nreturn {\n')
    for k_, (w_, h_) in sorted(sizes.items()):
        f.write('  %s = { %.3f, %.3f },\n' % (k_, w_, h_))
    f.write('}\n')
