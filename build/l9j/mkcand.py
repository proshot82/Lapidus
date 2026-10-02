#!/usr/bin/env python3
# build/l9j/mkcand.py имя "строка генератора" — превращает строку gen_*.txt в файл кандидата build/l9j/<имя>.lua
import sys, re
name, line = sys.argv[1], sys.argv[2]
parts = [p.strip() for p in line.split('|')]
grid = parts[1:10]
meta = parts[10]
m = dict(re.findall(r'(\w+)=([^ ]+)', meta))
L = m['L'].split('-')
tee = m['tee']; plug = m['plug']; head = int(m['head'])
cells = ', '.join('{ %s }' % c.replace(',', ', ') for c in m['lap'].split(';'))
g = ',\n    '.join('"%s"' % r for r in grid)
open('build/l9j/%s.lua' % name, 'w', encoding='utf-8').write('''-- кв. 9, кандидат %s (скелет «шахта»: колонка сверху, стояк снизу, лаз над сливом слева, боковой вход справа)
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "%s",
  length = { %s, %s }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    %s,
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { %s }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { %s }, ports = { right = "V" } },
    { kind = "lapidus", cells = { %s }, head = %d },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
''' % (name, name, L[0], L[1], g, tee.replace(',', ', '), plug.replace(',', ', '), cells, len(m['lap'].split(';')) if head != 1 else 1))
