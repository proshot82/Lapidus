#!/usr/bin/env python3
"""build/l4d/mk.py — собирает файл кандидата кв. 4 (формат levels/04.lua) из описания в build/l4d/specs.py.

python3 build/l4d/mk.py NAME [NAME2 ...]   → build/l4d/NAME.lua
Описание — словарь: grid, objects, comment, prepair ((x,y) муфты, (x,y) ниппеля для абляции «сборка заранее»),
[length, target, texts]. Видимый проигрыш — общий текст VIS (только добавляет к tools/vislib.lua). Решений нет.
"""
import sys, os, importlib

HERE = os.path.dirname(os.path.abspath(__file__))

TEXTS = {
    "request": "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    "hints": [
        "Трубу заранее не собирают: детали роняют по одной — сначала муфту, потом ниппель. Свинтятся сами, на месте.",
        "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
        "Мастер выехал. Детали он тоже роняет по одной.",
    ],
}

VIS = r'''
-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман). Видимо
-- проиграно «с одного взгляда», если:
--  1) ниппель уже закреплён в шахте под отводом, а муфты под ним нет: единственный вход в шахту закрыт им навсегда;
--  2) свободная одиночная деталь лежит на твёрдом там, откуда её никакими толчками не довести до входа в шахту
--     (статическая карта «мёртвых клеток», как углы в сокобане; по пути она прикрутилась бы к чужой резьбе или смылась);
--  3) свинченная пара лежит на твёрдом и зажата: её уже не сдвинуть ни влево, ни вправо;
--  4) вход прибора (машинки) навсегда занят прикрученной деталью: воде туда уже не попасть.
-- Не помечает (это «ага» уровня и мерка знатока): порядок свободных деталей на полу, подвижную свинченную пару,
-- деталь, прикрученную к чужой резьбе не в шахте.
local VL_GEO = setmetatable({}, { __mode = "k" })
local function vlGeom(lvl)
  local g = VL_GEO[lvl]
  if g then return g end
  g = { solid = {}, staticPort = {} }
  local S
  for q, p in ipairs(lvl.pieces) do
    if p.source then S = p.start end
    if p.what == "coupling" then g.qc = q elseif p.what == "nipple" then g.qn = q end
  end
  g.B = lvl.nb[S][1]; g.T = lvl.nb[g.B][1]
  local solid = g.solid
  for i = 1, lvl.N do solid[i] = (lvl.cell[i] == 1) end
  for q, p in ipairs(lvl.pieces) do
    if not p.movable then
      solid[p.start] = true
      g.staticPort[p.start] = p.ports
    end
  end
  local function isSolid(c) return c == 0 or solid[c] end
  local function isPit(c) return c ~= 0 and lvl.cell[c] == 2 end
  g.isSolid, g.isPit = isSolid, isPit
  local OPP = { 3, 4, 1, 2 }
  -- деталь q в клетке c прикрутилась бы к закреплённой резьбе (кроме входа в шахту)
  local function catches(q, c)
    if c == g.T then return false end
    local ports = lvl.pieces[q].ports
    for d = 1, 4 do
      local th = ports[d]
      local t = lvl.nb[c][d]
      if th and t ~= 0 and g.staticPort[t] then
        local o = g.staticPort[t][OPP[d]]
        if o and o ~= th then return true end
      end
    end
    return false
  end
  -- куда упадёт одиночная деталь q, отпущенная в клетке c (0 — смыло или прикрутилась не туда)
  local function rest(q, c)
    while true do
      if catches(q, c) then return 0 end
      local b = lvl.nb[c][3]
      if isSolid(b) then return c end
      if isPit(b) then return 0 end
      c = b
    end
  end
  local function pusherOK(t, set)
    if isSolid(t) or isPit(t) then return false end
    for d = 1, 4 do
      local u = lvl.nb[t][d]
      if u ~= 0 and not set[u] and not isSolid(u) and not isPit(u) then return true end
    end
    return false
  end
  g.pusherOK = pusherOK
  local reach = {}
  local function canReach(q, c0)
    local key = q * 1000 + c0
    if reach[key] ~= nil then return reach[key] end
    local seen, qu, h = { [c0] = true }, { c0 }, 1
    local ok = false
    while h <= #qu and not ok do
      local c = qu[h]; h = h + 1
      for _, d in ipairs({ 2, 4 }) do
        local c2 = lvl.nb[c][d]
        local back = lvl.nb[c][d == 2 and 4 or 2]
        if not isSolid(c2) and pusherOK(back, { [c] = true }) then
          if c2 == g.T then ok = true break end
          if not isPit(c2) then
            local r = rest(q, c2)
            if r ~= 0 and r == g.T then ok = true break end
            if r ~= 0 and not seen[r] then seen[r] = true; qu[#qu + 1] = r end
          end
        end
      end
    end
    reach[key] = ok
    return ok
  end
  g.canReach = canReach
  VL_GEO[lvl] = g
  return g
end

local function visibleLoss(lvl, st)
  local g = vlGeom(lvl)
  local qc, qn = g.qc, g.qn
  local pc, pn = st.pos[qc], st.pos[qn]
  if pc == 0 or pn == 0 then return true end
  -- 1) шахта закрыта ниппелем
  if st.fixed[qn] and pn == g.T and not st.fixed[qc] then return true end
  -- 4) вход прибора занят деталью
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[p.start][d]
          for r = 1, #st.pos do
            if lvl.pieces[r].movable and st.pos[r] == t and st.fixed[r] then return true end
          end
        end
      end
    end
  end
  local fixedAt = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 and st.fixed[q] then fixedAt[st.pos[q]] = true end end
  local function onHard(c) local b = lvl.nb[c][3]; return g.isSolid(b) or fixedAt[b] end
  local paired = (not st.fixed[qc]) and (not st.fixed[qn]) and st.asm[qc] == st.asm[qn]
  if paired then
    -- 3) пара зажата
    local cells = { pc, pn }
    local set = { [pc] = true, [pn] = true }
    if not (onHard(pc) or onHard(pn)) then return false end
    for _, d in ipairs({ 2, 4 }) do
      local free, pusher = true, false
      for _, c in ipairs(cells) do
        local c2 = lvl.nb[c][d]
        if not set[c2] and (g.isSolid(c2) or fixedAt[c2]) then free = false end
        local back = lvl.nb[c][d == 2 and 4 or 2]
        if not set[back] and not fixedAt[back] and g.pusherOK(back, set) then pusher = true end
      end
      if free and pusher then return false end
    end
    return true
  end
  -- 2) одиночная свободная деталь в «мёртвой клетке»
  for _, q in ipairs({ qc, qn }) do
    local c = st.pos[q]
    if not st.fixed[q] and onHard(c) and not g.canReach(q, c) then return true end
  end
  return false
end

-- Абляция РОЛИ приёма (фильтр ходов, как в levels/05.lua и levels/06.lua).
-- «По одной нельзя»: запрещено состояние, где муфта уже закреплена в шахте (на стояке), а ниппель ещё свободен,
-- то есть детали нельзя ронять по одной — только ставить вместе (собранной трубой).
local function oneByOne(lvl, st, ns)
  local qc, qn, S
  for q, p in ipairs(lvl.pieces) do
    if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end
    if p.source then S = p.start end
  end
  local B = lvl.nb[S][1]
  return not (ns.pos[qc] == B and ns.fixed[qc] and not ns.fixed[qn])
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
    grid = spec['grid']
    objs = spec['objects']
    (px, py), (qx, qy) = spec['prepair']
    mut = 'o.tag == "cpl" then o.at = { %d, %d } elseif o.tag == "nip" then o.at = { %d, %d }' % (px, py, qx, qy)
    length = spec.get('length', (2, 4))
    target = spec.get('target', '{ moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 }')
    texts = spec.get('texts', TEXTS)
    out = []
    for l in spec['comment'].strip().split('\n'):
        out.append('-- ' + l.strip())
    out.append(VIS.rstrip())
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
    out.append('    { name = "без муфты", remove = "cpl" },')
    out.append('    { name = "без ниппеля", remove = "nip" },')
    out.append('    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if %s end end end },' % mut)
    out.append('    { name = "по одной нельзя", filter = oneByOne },')
    for extra in spec.get('ablations', []):
        out.append('    ' + extra)
    out.append('  },')
    out.append('  texts = {')
    out.append('    request = %s,' % lua_str(texts['request']))
    out.append('    card = "card04",')
    out.append('    hints = {')
    for hnt in texts['hints']:
        out.append('      %s,' % lua_str(hnt))
    out.append('    },')
    out.append('  },')
    out.append('}')
    path = os.path.join(HERE, name + '.lua')
    open(path, 'w').write('\n'.join(out) + '\n')
    print('wrote', path)


if __name__ == '__main__':
    sys.path.insert(0, HERE)
    specs = importlib.import_module('specs').SPECS
    for name in sys.argv[1:]:
        build(name, specs[name])
