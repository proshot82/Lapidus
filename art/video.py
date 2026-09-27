#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""art/video.py — видео прохождения квартир 1–3 в утверждённом арте.

Кадры состояний берутся из build/video/playNN.json (tools/export_play.lua проигрывает оптимальные
решения солвера ядром правил, с трассой падений и толчков). Каждое состояние рисуется тем же
генератором, что и макеты; ffmpeg склеивает кадры с выдержками. Повторный запуск дорисовывает
недостающие кадры: python3 art/video.py [--encode]"""
import json, os, shutil, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, gen2, screens2
from gen import R, C, G, T, wrap, HAND
from gen2 import Q, frame, hero, bath2, toilet2, sink2, porcelain2, port2, hud2, defs2, DV

VID = os.path.join(gen2.ROOT, 'build', 'video')
L = screens2.L
OPPD = {'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}
DNAME = {(1, 0): 'right', (-1, 0): 'left', (0, 1): 'down', (0, -1): 'up'}
T0 = time.time()
BUDGET = float(os.environ.get('BUDGET', '240'))


def geom(lv):
    H, W = len(lv['grid']), len(lv['grid'][0])
    c = min(120, 1920 // W, 1080 // H)
    return c, (1920 - W * c) // 2, (1080 - H * c) // 2


def draw(name, body, extra):
    png = os.path.join(VID, name + '.png')
    if os.path.exists(png):
        return name + '.png'
    if time.time() - T0 > BUDGET:
        raise TimeoutError
    svg = os.path.join(VID, name + '.svg')
    with open(svg, 'w', encoding='utf-8') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080" viewBox="0 0 1920 1080"><defs>%s%s</defs>%s</svg>'
                % (gen.DEFS, extra, body))
    subprocess.run(['rsvg-convert', '-w', '1920', '-h', '1080', '-o', png, svg], check=True)
    return name + '.png'


def end_screw(cells, end, objs_at):
    e, nk, need = (cells[-1], cells[-2], 'N') if end == 'head' else (cells[0], cells[1], 'V')
    d = DNAME[(e[0] - nk[0], e[1] - nk[1])]
    ob = objs_at.get((e[0] + DV[d][0], e[1] + DV[d][1]))
    if ob and ob['kind'] in ('source', 'fixture', 'stub') and ob.get('ports', {}).get(OPPD[d]) == need:
        return ob
    return None


def state_layer(lv, fr, active, moves, bg):
    c, ox, oy = geom(lv)
    cc = lambda x, y: (ox + (x - .5) * c, oy + (y - .5) * c)
    objs = [o for o in lv['objects'] if o['kind'] != 'lapidus']
    at = {tuple(fr['pos'][q]): o for q, o in enumerate(objs) if fr['pos'][q]}
    cells = fr['cells']
    hs = None if fr['dead'] else end_screw(cells, 'head', at)
    ts = None if fr['dead'] else end_screw(cells, 'heel', at)
    wet = bool((hs and hs['kind'] == 'source') or (ts and ts['kind'] == 'source'))
    fwet = wet and bool((hs and hs['kind'] == 'fixture') or (ts and ts['kind'] == 'fixture'))
    s = ['<image href="%s" x="0" y="0" width="1920" height="1080"/>' % bg]
    for q, o in enumerate(objs):
        p = fr['pos'][q]
        if not p:
            continue
        cx, cy = cc(*p)
        if o['kind'] == 'fixture':
            pd, th = list(o['ports'].items())[0]
            body = {'bath': bath2, 'toilet': toilet2, 'sink': sink2}.get(o.get('what'), bath2)(cx, cy, c, fwet)
            if pd == 'right':
                body = G(body, transform='translate(%s 0) scale(-1 1)' % gen.n(2 * cx))
            s.append(G(body + port2(cx, cy - .02 * c, c, pd, th, True), filter='url(#dsh)'))
        elif o['kind'] == 'porcelain':
            s.append(G(porcelain2(cx, cy, c), filter='url(#dsh)'))
    if not fr['dead']:
        Lr = lv.get('length', [2, 4])
        s.append(hero([cc(x, y) for x, y in cells], c, Lr[0], Lr[1], active, (bool(ts), bool(hs)), True, wet))
        if wet:
            for end, scr in (('head', hs), ('heel', ts)):
                if scr:
                    continue
                e, nk = (cells[-1], cells[-2]) if end == 'head' else (cells[0], cells[1])
                d = DNAME[(e[0] - nk[0], e[1] - nk[1])]
                ex, ey = cc(*e)
                mx, my = ex + DV[d][0] * .45 * c, ey + DV[d][1] * .45 * c
                s.append(gen.drop(mx, my + .28 * c, .09 * c) + gen.drop(mx, my + .58 * c, .06 * c))
    s.append(hud2(lv, ox, moves, active))
    return ''.join(s), defs2(c, ox, oy, lv.get('tile', 'mint'))


def title_overlay(lv):
    lines = wrap(lv['texts']['request'], 30)
    inner = (T(960, 410, 'КВАРТИРА %d' % lv['flat'], 64, Q['cream'], weight='bold', anchor='middle', letter_spacing='6')
             + T(960, 478, '«%s»' % lv['name'], 52, '#F6DB8A', weight='bold', anchor='middle')
             + ''.join(T(960, 560 + k * 62, ln, 48, '#E6EEF5', font=HAND, anchor='middle') for k, ln in enumerate(lines)))
    return R(0, 0, 1920, 1080, '#000000', opacity='.6') + screens2.plate(460, 330, 1000, 250 + len(lines) * 62, inner)


def end_overlay(lv, moves):
    stamp = G(C(1500, 300, 150, 'none', stroke='#2B56B8', stroke_width=10) + C(1500, 300, 118, 'none', stroke='#2B56B8', stroke_width=4)
              + T(1500, 292, 'ВЫПОЛНЕНО', 46, '#2B56B8', weight='bold', anchor='middle') + T(1500, 338, 'ЖЭУ № 3', 30, '#2B56B8', weight='bold', anchor='middle'),
              transform='rotate(-14 1500 300)', opacity='.92')
    return stamp + screens2.plate(460, 896, 1000, 128, T(960, 948, 'Акт № %d подписан' % lv['flat'], 46, Q['cream'], weight='bold', anchor='middle')
                                  + T(960, 998, 'ходов %d при норме %d · 6-й разряд' % (moves, moves), 36, '#F6DB8A', anchor='middle'))


def build():
    os.makedirs(VID, exist_ok=True)
    seq = []
    intro = os.path.join(VID, 'intro.png')
    if not os.path.exists(intro):
        shutil.copy(os.path.join(gen2.ROOT, 'build', 'review2', '05_menu.png'), intro)
    seq.append(('intro.png', 2.4))
    for i, lv in enumerate(L):
        play = json.load(open(os.path.join(VID, 'play%02d.json' % lv['id']), encoding='utf-8'))
        frames = play['frames']
        body, extra, _ = frame(lv, no_lap=True, hud=False, skip=('fixture', 'porcelain'))
        bg = draw('bg%d' % lv['id'], body, extra)
        tag = 'k%d' % lv['id']
        b, e = state_layer(lv, frames[0], frames[0]['which'], 0, bg)
        seq.append((draw(tag + '_title', b + title_overlay(lv), e), 3.2))
        seq.append((draw(tag + '_000', b, e), 0.9))
        prev, active = frames[0], frames[0]['which']
        for k, fr in enumerate(frames[1:], 1):
            if fr['kind'] not in ('settle', 'wash') and fr['which'] != active:
                active = fr['which']
                b, e = state_layer(lv, prev, active, prev['move'], bg)
                seq.append((draw('%s_%03ds' % (tag, k), b, e), 0.42))
            b, e = state_layer(lv, fr, active, fr['move'], bg)
            seq.append((draw('%s_%03d' % (tag, k), b, e), 0.11 if fr['kind'] in ('settle', 'wash') else 0.28))
            prev = fr
        seq[-1] = (seq[-1][0], 1.2)
        b, e = state_layer(lv, prev, active, prev['move'], bg)
        seq.append((draw(tag + '_end', b + end_overlay(lv, play['moves']), e), 2.8))
    body, extra = screens2.select2(solved=(1, 2, 3), opened=())
    seq.append((draw('outro', body, extra), 3.4))
    return seq


def encode(seq):
    lst = os.path.join(VID, 'list.txt')
    with open(lst, 'w') as f:
        f.write('ffconcat version 1.0\n')
        for name, dur in seq:
            f.write("file '%s'\nduration %.3f\n" % (name, dur))
        f.write("file '%s'\n" % seq[-1][0])
    out = '/mnt/user-data/outputs/lapidus_walkthrough.mp4'
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', lst, '-vf', 'fps=30,format=yuv420p',
                    '-c:v', 'libx264', '-crf', '20', '-preset', 'veryfast', '-movflags', '+faststart', out], check=True, cwd=VID)
    return out


if __name__ == '__main__':
    try:
        seq = build()
    except TimeoutError:
        done = len([f for f in os.listdir(VID) if f.endswith('.png')])
        print('время вышло, готово кадров: %d — запустите ещё раз' % done)
        sys.exit(2)
    print('кадров в последовательности: %d, длительность %.1f с, отрисовано за %.0f с' % (len(seq), sum(d for _, d in seq), time.time() - T0))
    if '--encode' in sys.argv:
        print('видео:', encode(seq))
