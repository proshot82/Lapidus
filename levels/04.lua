-- Кв. 4 «Резьба» (28.09.2026, build/l4c, кандидат k35 — пересборка раскладки ради прогулок и честных ворот).
-- Шахта у стояка сверху закрыта отводом: войти в неё можно только сбоку, в одну клетку под отводом; снизу стояк (Н),
-- сверху отвод (В) — между ними нужны муфта (снизу) и ниппель (сверху). Муфта лежит на полу под машинкой, ниппель —
-- на самой машинке. Выход отвода смотрит на машинку: последнее звено — сам Лапидус, мостиком над коридором.
-- Ложный план: уронить ниппель на муфту и втолкнуть собранную трубу — в шахту она не пролезает. Второй: уронить
-- ниппель раньше, чем муфта уйдёт вперёд. Колонка слева от машинки — единственный спуск в левую часть коридора;
-- деталь, упавшая или вдвинутая в её низ, запечатывает кладовку за собой.
-- Видимый проигрыш — честный, «физический» (build/l4c/vis_main.lua); широкая разметка скептика — build/l4c/vis_wide.lua.
-- Решение здесь не пишется.

-- Видимо проиграно («с одного взгляда»), если:
--  1) ниппель уже закреплён под отводом, а муфты под ним нет: гнездо муфты замуровано;
--  2) свободная деталь лежит на твёрдом там, откуда её уже никак не затолкать в шахту: толкать можно только вбок,
--     встав концом рядом (с местом для шеи); поднять лежащее на полу нельзя; упавшее в слив смыто
--     (статическая карта «мёртвых клеток», как углы в сокобане; Лапидус и вторая деталь не учитываются);
--  3) свинченная пара лежит на твёрдом и зажата: её уже нельзя сдвинуть ни влево, ни вправо.
-- Не помечает: порядок свободных деталей на полу и свинченную пару, которую ещё можно двигать, — это «ага» уровня
-- (что собранная труба не пролезает, игрок видит, только поняв идею). Их помечает широкая версия (vis_wide.lua).
local VL_GEO = setmetatable({}, { __mode = "k" })
local function vlGeom(lvl)
  local g = VL_GEO[lvl]
  if g then return g end
  g = { solid = {} }
  local S
  for q, p in ipairs(lvl.pieces) do
    if p.source then S = p.start end
    if p.what == "coupling" then g.qc = q elseif p.what == "nipple" then g.qn = q end
  end
  g.B = lvl.nb[S][1]; g.T = lvl.nb[g.B][1]
  local solid = g.solid
  for i = 1, lvl.N do solid[i] = (lvl.cell[i] == 1) end
  for q, p in ipairs(lvl.pieces) do if not p.movable then solid[p.start] = true end end
  local function isSolid(c) return c == 0 or solid[c] end
  local function isPit(c) return c ~= 0 and lvl.cell[c] == 2 end
  g.isSolid, g.isPit = isSolid, isPit
  -- куда упадёт одиночная деталь, отпущенная в клетке c (0 — смыло)
  local function rest(c)
    while true do
      local b = lvl.nb[c][3]
      if isSolid(b) then return c end
      if isPit(b) then return 0 end
      c = b
    end
  end
  -- клетка t годится для толкающего конца: не твёрдая, не слив и есть куда деть шею (кроме клеток set)
  local function pusherOK(t, set)
    if isSolid(t) or isPit(t) then return false end
    for d = 1, 4 do
      local u = lvl.nb[t][d]
      if u ~= 0 and not set[u] and not isSolid(u) and not isPit(u) then return true end
    end
    return false
  end
  g.pusherOK = pusherOK
  -- статическая досягаемость шахты для одиночной детали, лежащей на твёрдом в клетке c
  local reach = {}
  local function canReach(c0)
    if reach[c0] ~= nil then return reach[c0] end
    local seen, q, h = { [c0] = true }, { c0 }, 1
    local ok = false
    while h <= #q and not ok do
      local c = q[h]; h = h + 1
      for _, d in ipairs({ 2, 4 }) do
        local c2 = lvl.nb[c][d]
        local back = lvl.nb[c][d == 2 and 4 or 2]
        if not isSolid(c2) and pusherOK(back, { [c] = true }) then
          if c2 == g.T then ok = true break end
          if not isPit(c2) then
            local r = rest(c2)
            if r ~= 0 and r == g.T then ok = true break end
            if r ~= 0 and not seen[r] then seen[r] = true; q[#q + 1] = r end
          end
        end
      end
    end
    reach[c0] = ok
    return ok
  end
  g.canReach = canReach
  VL_GEO[lvl] = g
  return g
end

-- 4) деталь запечатана (правило 29.09, по мерке новичка §7): свободная деталь лежит на твёрдом, а к клетке слева от неё,
--    откуда её толкают к шахте, Лапидусу уже не пройти (кладовка или карман за деталью).
local function sealed(lvl, st)
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  local lap = {}
  for _, c in ipairs(st.body) do lap[c] = true end
  local function open(c) return c ~= 0 and lvl.cell[c] == 0 end
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and st.asm[q] == q then
      local b = lvl.nb[c][3]
      local hard = b == 0 or lvl.cell[b] == 1 or (occ[b] and st.fixed[occ[b]])
      local left = lvl.nb[c][4]
      if hard and open(left) and not occ[left] then
        local seen, qu, h, found = { [left] = true }, { left }, 1, lap[left] or false
        while h <= #qu and not found do
          local u = qu[h]; h = h + 1
          for d = 1, 4 do
            local v = lvl.nb[u][d]
            if v ~= 0 and not seen[v] and v ~= c and open(v) and not (occ[v] and not lap[v]) then
              seen[v] = true; qu[#qu + 1] = v
              if lap[v] then found = true end
            end
          end
        end
        if not found then return true end
      end
    end
  end
  return false
end
local function visibleLoss(lvl, st)
  local g = vlGeom(lvl)
  local qc, qn = g.qc, g.qn
  local pc, pn = st.pos[qc], st.pos[qn]
  if pc == 0 or pn == 0 then return true end
  -- 1) гнездо муфты замуровано ниппелем
  if st.fixed[qn] and not st.fixed[qc] then return true end
  local fixedAt = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 and st.fixed[q] then fixedAt[st.pos[q]] = true end end
  local function onHard(c) local b = lvl.nb[c][3]; return g.isSolid(b) or fixedAt[b] end
  local paired = (not st.fixed[qc]) and (not st.fixed[qn]) and st.asm[qc] == st.asm[qn]
  if paired then
    -- 3) пара зажата
    local cells = { pc, pn }
    local set = { [pc] = true, [pn] = true }
    local rests = onHard(pc) or onHard(pn)
    if not rests then return false end
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
  if sealed(lvl, st) then return true end
  -- 2) одиночная свободная деталь в «мёртвой клетке»
  for _, q in ipairs({ qc, qn }) do
    local c = st.pos[q]
    if not st.fixed[q] and onHard(c) and not g.canReach(c) then return true end
  end
  return false
end

-- Абляции РОЛИ приёма (фильтры ходов, как в levels/05.lua и levels/06.lua).
-- «По одной нельзя»: запрещено состояние, где муфта уже закреплена в шахте, а ниппель ещё свободен,
-- то есть детали нельзя ронять по одной — только ставить вместе (собранной трубой).
local function tagOf(lvl, what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local function oneByOne(lvl, st, ns)
  local qc, qn = tagOf(lvl, "coupling"), tagOf(lvl, "nipple")
  return not (ns.pos[qc] ~= 0 and ns.fixed[qc] and not ns.fixed[qn])
end

return {
  visibleLoss = visibleLoss,
  id = 4, flat = 4, name = "Резьба",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "#########",
    "###....##",
    "###....##",
    "#.#.....#",
    "#.......#",
    "#######.#",
    "#######.#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 8, 7 }, ports = { up = "N" } },
    { kind = "pipe", at = { 8, 4 }, ports = { down = "V", left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 5 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fixture", what = "washer", at = { 5, 4 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 6, 2 }, { 6, 3 }, { 6, 4 }, { 6, 5 } }, head = 4 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "сборка заранее", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 5, 3 } elseif o.tag == "nip" then o.at = { 5, 2 } end end end },
    { name = "по одной нельзя", filter = oneByOne },
  },
  texts = {
    request = "Бельё замочено в машинке. Воду отключили. Бельё ждёт, я тоже.",
    hints = {
      "Трубу заранее не собирают: детали роняют по одной — сначала муфту, потом ниппель. Свинтятся сами, на месте.",
      "Ваш звонок очень важен для нас. Проверяем, не слиплось ли у вас что-нибудь лишнее.",
      "Мастер выехал. Детали он тоже роняет по одной.",
    },
  },
}
