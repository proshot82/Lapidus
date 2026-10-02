-- Кв. 4, контроль k40c: обе детали — переходники (порядок не важен). Не кандидат.

-- Видимый проигрыш уровня (только добавляет к общей линейке tools/vislib.lua: смыто, замёрзла, карман).
-- Разметка раунда 2 (после слепого скептика build/l4v/VERIFY.md). Видимо проиграно «с одного взгляда», если:
--  1) вход в шахту закрыт закреплённой деталью, а деталь, которая должна стоять на стояке, на стояке не стоит
--     (единственный вход в шахту закрыт навсегда);
--  2) подвижная деталь намертво прикручена к глухому отводу вне финальной сети (вкладыш: «прикрученная — намертво»);
--  3) вход прибора (машинки) навсегда занят прикрученной деталью: воде туда уже не попасть.
-- Не помечает (это «ага» уровня и мерка знатока): порядок свободных деталей на полу и подвижную свинченную пару.
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
  local S, B, T
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  B = lvl.nb[S][1]; T = lvl.nb[B][1]
  local atB, atT = nil, nil
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if st.pos[q] == 0 then return true end
      if st.pos[q] == B and st.fixed[q] then atB = q end
      if st.pos[q] == T and st.fixed[q] then atT = q end
    end
  end
  -- 1) вход закрыт, а на стояке пусто
  if atT and not atB then return true end
  return false
end

-- Абляция РОЛИ приёма (фильтр ходов): «по одной нельзя» — запрещено состояние, где нижняя деталь уже закреплена на стояке,
-- а верхняя ещё свободна (детали нельзя ронять по одной — только ставить вместе, собранной трубой).
local function oneByOne(lvl, st, ns)
  local S
  for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  local B = lvl.nb[S][1]
  local fixedB, freeOther = false, false
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if ns.pos[q] == B and ns.fixed[q] then fixedB = true elseif ns.pos[q] ~= 0 and not ns.fixed[q] then freeOther = true end
    end
  end
  return not (fixedB and freeOther)
end

return {
  visibleLoss = visibleLoss,
  id = 4, flat = 4, name = "Резьба",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "#.......##",
    "#.......##",
    "#####.#.##",
    "#........#",
    "#........#",
    "######.#.#",
    "########.#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 9, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 9, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { up = "N", down = "V" } },
    { kind = "fixture", what = "washer", at = { 7, 7 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 4, 3 }, { 4, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 5, 3 } elseif o.tag == "nip" then o.at = { 5, 2 } end end end },
    { name = "по одной нельзя", filter = oneByOne },
    { name = "контроль: порядок не важен (обе детали — переходники В/Н, отвод В)", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" or o.tag == "nip" then o.ports = { up = "N", down = "V" } elseif o.kind == "pipe" then o.ports = { down = "V", left = "N" } end end end },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    card = "card04",
    hints = {
      "Трубу заранее не собирают: детали роняют по одной — сначала муфту, потом ниппель. Свинтятся сами, на месте.",
      "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
      "Мастер выехал. Детали он тоже роняет по одной.",
    },
  },
}
