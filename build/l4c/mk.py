#!/usr/bin/env python3
"""build/l4c/mk.py — собирает самодостаточный файл кандидата кв. 4 (формат levels/04.lua) из описания.

python3 build/l4c/mk.py specs.NAME   → build/l4c/NAME.lua
Описание — словарь в build/l4c/specs.py: grid, objects, comment, [length, target, texts, hint1].
В файл вставляются: видимый проигрыш (текст build/l4c/vis_main.lua), фильтры абляций роли, тексты.
Решения в файлы не пишутся.
"""
import sys, os, importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))

TEXTS = {
    "request": "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    "hints": [
        "Трубу заранее не собирают: детали роняют по одной — сначала муфту, потом ниппель. Свинтятся сами, на месте.",
        "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
        "Мастер выехал. Детали он тоже роняет по одной.",
    ],
}

FILTERS = '''
-- Абляции РОЛИ приёма (фильтры ходов, как в levels/05.lua и levels/06.lua).
-- «По одной нельзя»: запрещено состояние, где муфта уже закреплена в шахте, а ниппель ещё свободен,
-- то есть детали нельзя ронять по одной — только ставить вместе (собранной трубой).
local function tagOf(lvl, what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local function oneByOne(lvl, st, ns)
  local qc, qn = tagOf(lvl, "coupling"), tagOf(lvl, "nipple")
  return not (ns.pos[qc] ~= 0 and ns.fixed[qc] and not ns.fixed[qn])
end
'''


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def obj_lua(o):
    parts = ['kind = "%s"' % o['kind']]
    if 'what' in o:
        parts.append('what = "%s"' % o['what'])
    if 'tag' in o:
        parts.append('tag = "%s"' % o['tag'])
    if o['kind'] == 'lapidus':
        cells = ', '.join('{ %d, %d }' % tuple(c) for c in o['cells'])
        parts.append('cells = { %s }' % cells)
        parts.append('head = %d' % o['head'])
    else:
        parts.append('at = { %d, %d }' % tuple(o['at']))
        ports = ', '.join('%s = "%s"' % (k, v) for k, v in o['ports'].items())
        parts.append('ports = { %s }' % ports)
    return '    { ' + ', '.join(parts) + ' },'


def build(name, spec):
    vis = open(os.path.join(HERE, 'vis_main.lua')).read()
    # убрать шапку-комментарий файла разработки и финальный return
    lines = vis.rstrip().split('\n')
    assert lines[-1].startswith('return visibleLoss')
    body = [l for l in lines[:-1]]
    while body and body[0].startswith('-- build/l4c/vis_main.lua'):
        body.pop(0)
    vis_body = '\n'.join(body)
    grid = spec['grid']
    objs = spec['objects']
    cpl = next(o for o in objs if o.get('what') == 'coupling')
    nip = next(o for o in objs if o.get('what') == 'nipple')
    # «сборка заранее»: ниппель кладут на муфту (или муфту под ниппель), дальше они свинчиваются сами
    cx, cy = cpl['at']
    nx, ny = nip['at']
    lapcells = set(tuple(c) for o in objs if o['kind'] == 'lapidus' for c in o['cells'])
    occupied = set(tuple(o['at']) for o in objs if o['kind'] != 'lapidus') | lapcells
    src = next(o for o in objs if o['kind'] == 'source')
    shaft = {(src['at'][0], src['at'][1] - 1), (src['at'][0], src['at'][1] - 2)}
    def free(x, y):
        return grid[y - 1][x - 1] == '.' and (x, y) not in occupied and (x, y) not in shaft
    if spec.get('prepair'):
        (px, py), (qx, qy) = spec['prepair']
        mut = 'o.tag == "cpl" then o.at = { %d, %d } elseif o.tag == "nip" then o.at = { %d, %d }' % (px, py, qx, qy)
    elif free(cx, cy - 1):
        mut = 'o.tag == "nip" then o.at = { %d, %d }' % (cx, cy - 1)
    elif free(nx, ny + 1):
        mut = 'o.tag == "cpl" then o.at = { %d, %d }' % (nx, ny + 1)
    else:
        # ближайшая к муфте пара свободных клеток «одна над другой»: муфту туда, ниппель на неё
        best = None
        for y in range(2, len(grid)):
            for x in range(2, len(grid[0])):
                if free(x, y) and free(x, y - 1):
                    d = abs(x - cx) + abs(y - cy)
                    if best is None or d < best[0]:
                        best = (d, x, y)
        if not best:
            raise SystemExit('нет места для «сборки заранее»')
        _, bx, by = best
        mut = 'o.tag == "cpl" then o.at = { %d, %d } elseif o.tag == "nip" then o.at = { %d, %d }' % (bx, by, bx, by - 1)
    length = spec.get('length', (2, 4))
    target = spec.get('target', '{ moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 }')
    texts = spec.get('texts', TEXTS)
    out = []
    for l in spec['comment'].strip().split('\n'):
        out.append('-- ' + l.strip())
    out.append('')
    out.append(vis_body.strip())
    out.append(FILTERS.rstrip())
    out.append('')
    out.append('return {')
    out.append('  visibleLoss = visibleLoss,')
    out.append('  id = 4, flat = 4, name = "Резьба",')
    out.append('  length = { %d, %d }, pressure = 0, tile = "mint",' % tuple(length))
    out.append('  target = %s,' % target)
    out.append('  grid = {')
    for row in grid:
        out.append('    "%s",' % row)
    out.append('  },')
    out.append('  objects = {')
    for o in objs:
        o = dict(o)
        if o.get('what') == 'coupling':
            o['tag'] = 'cpl'
        if o.get('what') == 'nipple':
            o['tag'] = 'nip'
        out.append(obj_lua(o))
    out.append('  },')
    out.append('  ablations = {')
    out.append('    { name = "без деталей", remove = "part" },' if False else '    { name = "без муфты", remove = "cpl" },')
    out.append('    { name = "без ниппеля", remove = "nip" },')
    out.append('    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if %s end end end },' % mut)
    out.append('    { name = "по одной нельзя", filter = oneByOne },')
    out.append('  },')
    out.append('  texts = {')
    out.append('    request = %s,' % lua_str(texts['request']))
    out.append('    hints = {')
    for hnt in texts['hints']:
        out.append('      %s,' % lua_str(hnt))
    out.append('    },')
    out.append('  },')
    out.append('}')
    path = os.path.join(HERE, name + '.lua')
    open(path, 'w').write('\n'.join(out) + '\n')
    return path


if __name__ == '__main__':
    spec_path = os.path.join(HERE, 'specs.py')
    sp = importlib.util.spec_from_file_location('specs', spec_path)
    m = importlib.util.module_from_spec(sp)
    sp.loader.exec_module(m)
    for arg in sys.argv[1:]:
        print(build(arg, m.SPECS[arg]))
