#!/usr/bin/env python3
# build/l1c/mk.py имя "ряд1|ряд2|..." S=x,y:сторона=резьба F=x,y:сторона=резьба T=x,y:сторона=резьба [T2=...]
#                 LAP=x,y;x,y;... (от ног к голове) [LEN=2,4] [NOTE=текст]
# Пишет полный файл уровня build/l1c/<имя>.lua: видимый проигрыш (мерка новичка, vl_flip.lua.txt), абляции роли,
# цель, тексты. Решение в файл не пишется.
import sys, os
here = os.path.dirname(os.path.abspath(__file__))
name, grid = sys.argv[1], sys.argv[2].split('|')
kv = {}
for a in sys.argv[3:]:
    k, v = a.split('=', 1)
    kv[k] = v
W = len(grid[0])
for r in grid:
    assert len(r) == W, 'ширина ряда: ' + r


def obj(spec):
    at, port = spec.split(':')
    side, th = port.split('=')
    x, y = at.split(',')
    return x.strip(), y.strip(), side, th


lines = []
sx, sy, ss, st = obj(kv['S'])
lines.append('    { kind = "source", at = { %s, %s }, ports = { %s = "%s" } },' % (sx, sy, ss, st))
fx, fy, fs, ft = obj(kv['F'])
lines.append('    { kind = "fixture", what = "bath", at = { %s, %s }, ports = { %s = "%s" } },' % (fx, fy, fs, ft))
for key in ('T', 'T2', 'T3'):
    if key in kv:
        tx, ty, ts, tt = obj(kv[key])
        tag = 'hook' if key == 'T' else 'hook' + key[1:]
        lines.append('    { kind = "stub", tag = "%s", at = { %s, %s }, ports = { %s = "%s" } },' % (tag, tx, ty, ts, tt))
cells = [c.split(',') for c in kv['LAP'].split(';')]
lap = ', '.join('{ %s, %s }' % (c[0].strip(), c[1].strip()) for c in cells)
lines.append('    { kind = "lapidus", cells = { %s }, head = %d },' % (lap, len(cells)))
vl = open(os.path.join(here, 'vl_flip.lua.txt'), encoding='utf-8').read()
note = kv.get('NOTE', '')
g = ',\n    '.join('"%s"' % r for r in grid)
out = '''-- Квартира 1 «Не той стороной» — кандидат build/l1c/%s.lua. %s
-- Решение здесь не пишется. Проверка: luajit build/l6b/check.lua <файл>; разбор: luajit build/l1c/an.lua <файл>.
%s
-- Абляции РОЛИ: крюк — единственная точка опоры для разворота.
local function noHook(lvl, st, ns)
  local R = require("core.rules")
  local piece = R.occupancy(ns)
  for _, which in ipairs({ "head", "heel" }) do
    local q = R.endScrew(lvl, ns, piece, which)
    if q and lvl.pieces[q].kind == "stub" then return false end
  end
  return true
end

return {
  visibleLoss = visibleLoss,
  id = 1, flat = 1, name = "Не той стороной",
  length = { %s }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 20000, dead = 25, fb = 1 },
  grid = {
    %s,
  },
  objects = {
%s
  },
  ablations = {
    { name = "без крюка", remove = "hook" },
    { name = "крюк без крепления", filter = noHook },
  },
  texts = {
    request = "Ванна есть. Воды нет. Прошу наоборот.",
    hints = {
      "Развернуться можно, только повиснув на чужой резьбе. Прикрутите сначала «не тот» конец.",
      "Ваш звонок очень важен для нас. Проверяем, есть ли у вас выход.",
      "Мастер выехал. Смотрите внимательно: второй раз он не приедет.",
    },
  },
}
''' % (name, note, vl.rstrip(), kv.get('LEN', '2, 4'), g, '\n'.join(lines))
open(os.path.join(here, name + '.lua'), 'w', encoding='utf-8').write(out)
print('build/l1c/%s.lua' % name)
