#!/usr/bin/env python3
"""build/l5d/mk.py — сборка ПОЛНОГО файла кандидата кв. 5 из ручной раскладки (specs.py).
Раскладка (сетка, детали, старт) — руками в specs.py; скрипт вставляет видимый проигрыш уровня, фильтры абляций
и контролей, тексты. Использование: python3 build/l5d/mk.py имя [имя ...]"""
import os, sys, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('specs', os.path.join(HERE, 'specs.py'))
S = importlib.util.module_from_spec(spec); spec.loader.exec_module(S)

COMMON = open(os.path.join(HERE, 'common.lua'), encoding='utf-8').read()

def ports(p):
    return ', '.join('%s = "%s"' % (k, v) for k, v in p.items())

def build(name, sp):
    grid = sp['grid']; W = len(grid[0])
    assert all(len(r) == W for r in grid), name
    assert W <= 12 and len(grid) <= 8, name
    L = []
    L.append('-- Квартира 5 «Лишний выход» — кандидат %s (30.09.2026, build/l5d).' % name)
    for c in sp.get('comment', []):
        L.append('-- ' + c)
    L.append('-- Решение здесь не пишется.')
    L.append('')
    L.append(COMMON.rstrip())
    L.append('')
    L.append('return {')
    L.append('  visibleLoss = visibleLoss,')
    L.append('  id = 5, flat = 5, name = "Лишний выход",')
    L.append('  length = { %d, %d }, pressure = 0, tile = "blue",' % tuple(sp['length']))
    L.append('  target = { moves = { 15, 40 }, states = 300000, dead = 25, fb = 2 },')
    L.append('  grid = {')
    for r in grid: L.append('    "%s",' % r)
    L.append('  },')
    L.append('  objects = {')
    for o in sp['objects']:
        if o[0] == 'source':
            L.append('    { kind = "source", at = { %d, %d }, ports = { %s } },' % (o[1], o[2], ports(o[3])))
        elif o[0] == 'dryer':
            L.append('    { kind = "fixture", what = "dryer", at = { %d, %d }, ports = { %s } },' % (o[1], o[2], ports(o[3])))
        elif o[0] == 'stub':
            L.append('    { kind = "stub", at = { %d, %d }, ports = { %s } },' % (o[1], o[2], ports(o[3])))
        elif o[0] == 'porcelain':
            L.append('    { kind = "porcelain", tag = "%s", at = { %d, %d } },' % (o[3], o[1], o[2]))
        else:  # fitting: (what, x, y, ports, tag)
            L.append('    { kind = "fitting", what = "%s", tag = "%s", at = { %d, %d }, ports = { %s } },' % (o[0], o[4], o[1], o[2], ports(o[3])))
    cells = ', '.join('{ %d, %d }' % c for c in sp['lap'])
    L.append('    { kind = "lapidus", cells = { %s }, head = %d },' % (cells, sp.get('head', 1)))
    L.append('  },')
    L.append('  ablations = {')
    L.append('    { name = "без заглушки", remove = "plug" },')
    L.append('    { name = "тройник без лишнего выхода, заглушки нет", remove = "plug",')
    L.append('      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },')
    L.append('    { name = "ступенька запрещена (стоя на свободной заглушке, не выше, чем с пола)", filter = noStep },')
    for a in sp.get('ablations', []): L.append('    ' + a)
    L.append('  },')
    L.append('  controls = {')
    L.append('    { name = "контроль: тройник без лишнего выхода, заглушка есть (только ступенька)",')
    L.append('      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },')
    for c in sp.get('controls', []): L.append('    ' + c)
    L.append('  },')
    L.append('  texts = {')
    L.append('    request = "Полотенцесушитель холодный, носки мокрые. Пропажу второго носка прошу считать отдельной заявкой.",')
    L.append('    card = "card05",')
    L.append('    hints = {')
    for h in sp.get('hints', S.HINTS): L.append('      "%s",' % h)
    L.append('    },')
    L.append('  },')
    L.append('}')
    out = os.path.join(HERE, name + '.lua')
    open(out, 'w', encoding='utf-8').write('\n'.join(L) + '\n')
    print('записан', out)

if __name__ == '__main__':
    for n in sys.argv[1:]:
        build(n, S.SPECS[n])
