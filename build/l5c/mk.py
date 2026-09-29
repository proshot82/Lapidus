#!/usr/bin/env python3
"""build/l5c/mk.py — сборка ПОЛНОГО файла уровня-кандидата кв. 5 из ручной раскладки.
Раскладку (сетку, детали, старт) задаю руками в SPECS ниже; скрипт только вставляет видимый проигрыш
(build/l5c/vis_novice.lua), абляции ролей и тексты, чтобы кандидат был самодостаточным (без dofile).
Использование: python3 build/l5c/mk.py имя [имя ...]
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))

def vis_code():
    src = open(os.path.join(HERE, 'vis_novice.lua'), encoding='utf-8').read()
    body = src[:src.rindex('return visibleLoss')]
    return body.rstrip() + '\n'

ROLE = r'''
-- Абляции РОЛИ приёма (фильтры ходов, как в levels/04.lua и levels/06.lua).
local function tagOf(lvl, what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
-- «Ступенька запрещена»: нельзя сдвинуть тройник, пока Лапидус опирается на незакреплённую заглушку
-- (стоит на ней хоть одним звеном) — заглушка не служит лестницей.
local function noStep(lvl, st, ns)
  local tq, pq = tagOf(lvl, "tee"), tagOf(lvl, "plug")
  if st.pos[tq] == ns.pos[tq] or st.fixed[tq] then return true end
  local pc = st.pos[pq]
  if pc == 0 or st.fixed[pq] then return true end
  local above = lvl.nb[pc][1]
  for _, c in ipairs(st.body) do if c == above then return false end end
  return true
end
'''

TEXTS = r'''  texts = {
    request = "Полотенцесушитель холодный, носки мокрые. Пропажу второго носка прошу считать отдельной заявкой.",
    hints = {
      "Заглушка — единственная ступенька наверх. Сначала лестница, потом пробка.",
      "Ваш звонок очень важен для нас. Проверяем, не лишний ли у вас выход.",
      "Мастер выехал. Стремянку он с собой не возит.",
    },
  },
'''

def lua_obj(o):
    return o

def build(name, spec):
    grid = spec['grid']
    W = len(grid[0])
    for r in grid:
        assert len(r) == W, (name, r)
    lines = []
    lines.append('-- ' + spec['title'])
    for c in spec.get('comment', []):
        lines.append('-- ' + c)
    lines.append('-- Решение здесь не пишется.')
    lines.append('')
    lines.append(vis_code())
    lines.append(ROLE)
    lines.append('return {')
    lines.append('  visibleLoss = visibleLoss,')
    lines.append('  id = 5, flat = 5, name = "Лишний выход",')
    lines.append('  length = { %d, %d }, pressure = 0, tile = "blue",' % tuple(spec['length']))
    lines.append('  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },')
    lines.append('  grid = {')
    for r in grid:
        lines.append('    "%s",' % r)
    lines.append('  },')
    lines.append('  objects = {')
    sx, sy = spec['source']
    lines.append('    { kind = "source", at = { %d, %d }, ports = { left = "N" } },' % (sx, sy))
    dx, dy = spec['dryer']
    lines.append('    { kind = "fixture", what = "dryer", at = { %d, %d }, ports = { left = "N" } },' % (dx, dy))
    tx, ty = spec['tee']
    lines.append('    { kind = "fitting", what = "tee", tag = "tee", at = { %d, %d }, ports = { up = "V", right = "V", left = "V" } },' % (tx, ty))
    px, py = spec['plug']
    lines.append('    { kind = "fitting", what = "plug", tag = "plug", at = { %d, %d }, ports = { right = "N" } },' % (px, py))
    cells = ', '.join('{ %d, %d }' % c for c in spec['lap'])
    lines.append('    { kind = "lapidus", cells = { %s }, head = %d },' % (cells, spec.get('head', 1)))
    lines.append('  },')
    lines.append('  ablations = {')
    lines.append('    { name = "без заглушки", remove = "plug" },')
    lines.append('    { name = "тройник заглушён заранее", remove = "plug",')
    lines.append('      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },')
    lines.append('    { name = "ступенька запрещена", filter = noStep },')
    for extra in spec.get('ablations', []):
        lines.append('    ' + extra)
    lines.append('  },')
    lines.append(TEXTS.rstrip('\n'))
    lines.append('}')
    out = os.path.join(HERE, name + '.lua')
    open(out, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('записан', out)

SPECS = {}

# a2: тоннель под блоком полки — заглушка, вошедшая в тоннель, обратно не выходит; сброс в гнездо P.
SPECS['a2'] = dict(
    title='a2: полка-блок над тоннелем; заглушка — ступенька в левой шахте; тоннель и сброс к гнезду P.',
    length=(2, 4),
    grid=[
        "#########",
        "#......##",
        "#..##..##",
        "#..##..##",
        "#..##...#",
        "#......##",
        "####...##",
        "#########",
    ],
    source=(7, 7), dryer=(8, 5), tee=(4, 2), plug=(3, 6),
    lap=[(2, 4), (2, 5), (2, 6)], head=1,
)

if __name__ == '__main__':
    for n in sys.argv[1:]:
        build(n, SPECS[n])
