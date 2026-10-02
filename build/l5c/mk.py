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
-- Абляция РОЛИ приёма (фильтр ходов, как в levels/04.lua и levels/06.lua).
-- «Ступенька запрещена»: стоя на незакреплённой заглушке, Лапидус не поднимается выше, чем достаёт с пола
-- (ни одно звено не выше клетки «заглушка − 4»), — заглушка не служит лестницей. Остальное (ходить по ней,
-- толкать её, лежать на ней) разрешено.
local function tagOf(lvl, what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local function noStep(lvl, st, ns)
  local pq = tagOf(lvl, "plug")
  local c = ns.pos[pq]
  if c == 0 or ns.fixed[pq] then return true end
  local above = lvl.nb[c][1]
  local on = false
  for _, b in ipairs(ns.body) do if b == above then on = true end end
  if not on then return true end
  local pr = math.floor((c - 1) / lvl.W) + 1
  for _, b in ipairs(ns.body) do if math.floor((b - 1) / lvl.W) + 1 <= pr - 4 then return false end end
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
    # коридор солвера — как у нынешней levels/05.lua (не меняю: качество меряют ворота общей линейки)
    lines.append('  target = { moves = { 15, 40 }, states = 100000, dead = 35, fb = 1 },')
    lines.append('  grid = {')
    for r in grid:
        lines.append('    "%s",' % r)
    lines.append('  },')
    lines.append('  objects = {')
    sx, sy = spec['source']
    lines.append('    { kind = "source", at = { %d, %d }, ports = { left = "N" } },' % (sx, sy))
    dx, dy = spec['dryer']
    lines.append('    { kind = "fixture", what = "dryer", at = { %d, %d }, ports = { %s = "N" } },' % (dx, dy, spec.get('dryer_port', 'left')))
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

# k1: ядро c1 «лестница, потом пробка» — тройник на уступе между колонной над стояком и сушителем; правильный толчок —
# только из закутка у сушителя (лаз сверху, наверх — единственная ступенька-заглушка); гнездо — ямка у стояка.
K1_COMMENT = [
    'Тройник лежит на уступе между выходом к стояку (колонна над стояком) и сушителем. Толкнуть его в колонну можно',
    'только со стороны сушителя — из закутка, куда ведёт лишь лаз сверху; наверх ведёт единственная ступенька —',
    'заглушка. Снизу (из колонны) тройник толкается легко — но в другую сторону, прямо на резьбу сушителя.',
    'Гнездо заглушки — ямка у тройника на стояке: упавшая туда заглушка уже не выйдет.',
    'Ложный план: «заглушку — сразу в гнездо у стояка» (тогда ступеньки больше нет) и «тройник — на сушитель»',
    '(правдоподобная неверная пара). Правильный порядок: сначала лестница, потом пробка.',
    'Видимый проигрыш — по мерке новичка (общая линейка tools/vislib.lua + правило уровня ниже).',
]
K1_GRID = [
    "#########",
    "#......##",
    "#..###.##",
    "#...##.##",
    "#.......#",
    "#....####",
    "###...###",
    "#########",
]
SPECS['k1'] = dict(
    title='Квартира 5 «Лишний выход» — кандидат k1 (29.09.2026, build/l5c; ядро c1 «лестница, потом пробка»).',
    comment=K1_COMMENT, length=(2, 4), grid=K1_GRID,
    source=(6, 7), dryer=(8, 5), tee=(6, 5), plug=(3, 6),
    lap=[(2, 4), (2, 5), (2, 6)], head=1,
)
# k2: k1 со стартом «Лапидус опирается на заглушку» (прогулка короче на 2, ошибка подсказки №1 — в 1 ходе от старта).
SPECS['k2'] = dict(
    title='Квартира 5 «Лишний выход» — кандидат k2 (29.09.2026, build/l5c; k1 со стартом «опирается на заглушку»).',
    comment=K1_COMMENT, length=(2, 4), grid=K1_GRID,
    source=(6, 7), dryer=(8, 5), tee=(6, 5), plug=(3, 6),
    lap=[(3, 4), (3, 5), (2, 5), (2, 6)], head=1,
)

# Семейство V' (для сравнения, 29.09): стояк внизу колонны, сушитель — над колонной (резьба вниз); закуток толчка — рядом
# с лестницей за стенкой; заглушка идёт к гнезду низким лазом. Прогулка короче, но нет ложной пары «тройник на сушитель».
V_GRID_WIDE = [
    "#########",
    "#....#.##",
    "#..#.#.##",
    "#..#...##",
    "#..###.##",
    "#......##",
    "#####...#",
    "#########",
]
SPECS['v1'] = dict(
    title='v1: колонна стояка под сушителем; закуток толчка рядом с лестницей за стенкой; низкий лаз заглушки к гнезду.',
    comment=['Ложный план: заглушку — сразу по лазу в гнездо (ступеньки больше нет).'],
    length=(2, 4), grid=V_GRID_WIDE,
    source=(8, 7), dryer=(7, 2), dryer_port='down', tee=(6, 4), plug=(3, 6),
    lap=[(2, 4), (2, 5), (2, 6)], head=1,
)
SPECS['v2'] = dict(
    title='v2: как v1, левая комната узкая (без разворота до толчка тройника), старт головой к заглушке.',
    comment=['Ложный план: заглушку — сразу по лазу в гнездо (ступеньки больше нет).'],
    length=(2, 4),
    grid=[
        "#########",
        "##...#.##",
        "##.#.#.##",
        "##.#...##",
        "#..###.##",
        "#......##",
        "#####...#",
        "#########",
    ],
    source=(8, 7), dryer=(7, 2), dryer_port='down', tee=(6, 4), plug=(3, 6),
    lap=[(2, 6), (2, 5), (3, 5), (3, 4)], head=1,
)

if __name__ == '__main__':
    for n in sys.argv[1:]:
        build(n, SPECS[n])
