#!/usr/bin/env python3
"""Ниши у приборов: какие свободные клетки рядом с прибором можно заложить стеной, не меняя уровень
(та же длина решения, одна выигрышная сборка, абляции те же). python3 build/p6/niche/try.py"""
import re, subprocess, os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
os.chdir(ROOT)
def check(path):
    out = subprocess.run(['luajit', 'build/l6b/check.lua', path], capture_output=True, text=True, timeout=1200).stdout
    m = re.search(r'ходов (\d+) \| состояний (\d+).*выигрышных (\d+)', out)
    ab = re.search(r'абляции: (.*)', out)
    if not m: return None
    return int(m.group(1)), int(m.group(2)), int(m.group(3)), ab.group(1).strip() if ab else ''
for n in range(1, 11):
    path = 'levels/%02d.lua' % n
    src = open(path, encoding='utf-8').read()
    g0 = src.index('grid = {'); g1 = src.index('}', g0)
    rows = re.findall(r'"([^"]*)"', src[g0:g1])
    fx = re.findall(r'kind = "fixture".*?at = \{ (\d+), (\d+) \}', src)
    base = check(path)
    cands = []
    for fxs in fx:
        x, y = int(fxs[0]), int(fxs[1])
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                xx, yy = x + dx, y + dy
                if (dx or dy) and 1 <= yy <= len(rows) and 1 <= xx <= len(rows[0]) and rows[yy - 1][xx - 1] == '.':
                    cands.append((xx, yy))
    ok = []
    for (xx, yy) in cands:
        r2 = list(rows); r2[yy - 1] = r2[yy - 1][:xx - 1] + '#' + r2[yy - 1][xx:]
        new = src[:g0] + src[g0:g1].replace('"%s"' % rows[yy - 1], '"%s"' % r2[yy - 1], 1) + src[g1:]
        tmp = 'build/p6/niche/_t%02d.lua' % n
        open(tmp, 'w', encoding='utf-8').write(new)
        try:
            res = check(tmp)
        except Exception as e:
            res = None
        same = res is not None and res[0] == base[0] and res[2] == base[2] and res[3] == base[3]
        print('кв.%d клетка (%d,%d): %s %s' % (n, xx, yy, 'МОЖНО' if same else 'нельзя', res[:3] if res else 'нерешаем/ошибка'), flush=True)
        if same: ok.append((xx, yy))
    print('кв.%d база %s; можно заложить: %s' % (n, base[:3], ok), flush=True)
