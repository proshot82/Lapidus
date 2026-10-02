-- Кв. 4 «Резьба», кандидат k27 (build/l4d): k24 без отвода Н справа от муфты. Решение здесь не пишется.

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

return {
  visibleLoss = visibleLoss,
  id = 4, flat = 4, name = "Резьба",
  length = { 2, 3 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "##....#####",
    "##.......##",
    "##....#...#",
    "#.........#",
    "#.........#",
    "######.#.##",
    "########.##",
    "###########",
  },
  objects = {
    { kind = "source", at = { 9, 8 }, ports = { up = "N" } },
    { kind = "pipe", at = { 9, 5 }, ports = { down = "V", left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fixture", what = "washer", at = { 7, 7 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 6, 5 } }, head = 1 },
    { kind = "stub", at = { 4, 4 }, ports = { up = "V" } },
    { kind = "stub", at = { 6, 2 }, ports = { down = "V" } },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 4, 3 } elseif o.tag == "nip" then o.at = { 4, 2 } end end end },
    { name = "по одной нельзя", filter = oneByOne },
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
