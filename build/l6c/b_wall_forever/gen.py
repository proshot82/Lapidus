#!/usr/bin/env python3
"""gen.py имя < спецификация
Спецификация: строки карты (# . ~ и буквы объектов), затем пустая строка, затем строки 'буква: описание'.
  S: source right=N          F: heater down=V          T: stub up=N
  c: coupling tag=cpl left=V right=V     (любые буквы деталей; tag= необязателен)
  P: porcelain
Лапидус: f — ноги, o — тело, H — голова (цепочка восстанавливается по соседству).
Опции: LEN=3,5  VIS=имя_функции_из_vis.lua  ABL=строка Lua (содержимое ablations)  NOTE=комментарий
"""
import sys, re
name = sys.argv[1]
text = sys.stdin.read().split('\n')
grid = []
i = 0
while i < len(text) and text[i].strip():
    grid.append(text[i].rstrip()); i += 1
defs = {}
opts = {}
for line in text[i:]:
    line = line.strip()
    if not line: continue
    if re.match(r'^[A-Z]+=', line):
        k, v = line.split('=', 1); opts[k] = v; continue
    k, v = line.split(':', 1)
    defs[k.strip()] = v.strip()
W = len(grid[0])
assert all(len(r) == W for r in grid), [len(r) for r in grid]
cells = {}
out_grid = []
for y, row in enumerate(grid, 1):
    r = ''
    for x, ch in enumerate(row, 1):
        if ch in '#.~':
            r += ch
        else:
            r += '.'
            cells.setdefault(ch, []).append((x, y))
    out_grid.append(r)
# Лапидус
lap = {(x, y): 'f' for (x, y) in cells.get('f', [])}
for c in cells.get('o', []): lap[c] = 'o'
for c in cells.get('H', []): lap[c] = 'H'
assert len(cells.get('f', [])) == 1 and len(cells.get('H', [])) == 1
start = cells['f'][0]
chain = [start]
seen = {start}
while True:
    x, y = chain[-1]
    nxt = [c for c in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)] if c in lap and c not in seen]
    if lap[chain[-1]] == 'H': break
    assert len(nxt) == 1 or (len(nxt) > 1 and any(lap[c]=='H' for c in nxt) and len(chain) == len(lap)-1), ('ambiguous body', chain, nxt)
    if len(nxt) > 1: nxt = [c for c in nxt if lap[c] == 'H']
    chain.append(nxt[0]); seen.add(nxt[0])
assert len(chain) == len(lap)
objs = []
KIND = {}
for ch, pts in cells.items():
    if ch in 'foH': continue
    assert ch in defs, 'нет описания для ' + ch
    d = defs[ch].split()
    kindword = d[0]
    extra = {}
    ports = {}
    for tok in d[1:]:
        k, v = tok.split('=')
        if k in ('up', 'down', 'left', 'right'): ports[k] = v
        else: extra[k] = v
    for (x, y) in pts:
        if kindword == 'source': s = '{ kind = "source", at = { %d, %d }' % (x, y)
        elif kindword == 'heater': s = '{ kind = "fixture", what = "heater", at = { %d, %d }' % (x, y)
        elif kindword == 'stub': s = '{ kind = "stub", at = { %d, %d }' % (x, y)
        elif kindword == 'porcelain': s = '{ kind = "porcelain", at = { %d, %d }' % (x, y)
        else: s = '{ kind = "fitting", what = "%s", at = { %d, %d }' % (kindword, x, y)
        if 'tag' in extra: s += ', tag = "%s"' % extra['tag']
        if ports: s += ', ports = { ' + ', '.join('%s = "%s"' % (k, v) for k, v in ports.items()) + ' }'
        s += ' },'
        objs.append((kindword, s))
order = {'source': 0, 'heater': 1, 'stub': 2}
objs.sort(key=lambda t: order.get(t[0], 3))
lapcells = ', '.join('{ %d, %d }' % c for c in chain)
length = opts.get('LEN', '3,5')
note = opts.get('NOTE', '')
vis = opts.get('VIS', 'vis')
abl = opts.get('ABL', '')
lua = '''-- %s
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.%s,
  id = 6, flat = 6, name = "Намертво", length = { %s }, pressure = 0, tile = "mustard",
  grid = {
%s
  },
  objects = {
%s
    { kind = "lapidus", cells = { %s }, head = %d },
  },
  ablations = { %s },
}
''' % (note, vis, length.replace(',', ', '), '\n'.join('    "%s",' % r for r in out_grid), '\n'.join('    ' + s for _, s in objs), lapcells, len(chain), abl)
open(name if name.endswith('.lua') else name + '.lua', 'w', encoding='utf-8').write(lua)
print('ok', name)
