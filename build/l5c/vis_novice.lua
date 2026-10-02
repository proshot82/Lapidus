-- Видимый проигрыш уровня (правило уровня; общая линейка tools/vislib.lua его дополняет) — по мерке НОВИЧКА:
--  1) свободная деталь (тройник или заглушка), лежащая на твёрдом (стена или закреплённое), статически уже не может
--     попасть на своё место: толкать можно только вбок, встав концом рядом (с местом для шеи); поднять лежащее нельзя;
--     падающая деталь ловится резьбой на лету; упавшее в слив смыто (как углы в сокобане; Лапидус и вторая деталь
--     не учитываются). Место тройника — клетка у выхода стояка, место заглушки — клетка у левого выхода тройника;
--  2) заглушка закреплена не у тройника на стояке (её резьба никуда не ведёт);
--  3) свинченная пара «заглушка + тройник», которую уже нельзя сдвинуть ни влево, ни вправо.
-- Не помечает (для новичка скрыто): заглушку, отправленную в гнездо раньше, чем она послужила лестницей (порядок),
-- и тройник на резьбе сушителя (неверная пара — чтобы увидеть ошибку, надо знать финальную сборку).
local VL_GEO = setmetatable({}, { __mode = "k" })
local function vlGeom(lvl)
  local g = VL_GEO[lvl]
  if g then return g end
  g = {}
  for q, p in ipairs(lvl.pieces) do
    if p.source then g.src = q elseif p.fixture then g.fix = q
    elseif p.what == "tee" then g.tee = q elseif p.what == "plug" then g.plug = q end
  end
  local S = lvl.pieces[g.src].start
  local sd
  for d = 1, 4 do if lvl.pieces[g.src].ports[d] then sd = d end end
  g.T = lvl.nb[S][sd]                    -- место тройника: клетка перед выходом стояка
  g.P = lvl.nb[g.T][4]                   -- место заглушки: слева от тройника
  VL_GEO[lvl] = g
  return g
end

local function visibleLoss(lvl, st)
  local g = vlGeom(lvl)
  local P, T = g.P, g.T
  local qt, qp = g.tee, g.plug
  if st.pos[qt] == 0 or st.pos[qp] == 0 then return true end
  local fixedAt = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 and st.fixed[q] then fixedAt[st.pos[q]] = q end end
  local function solid(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] ~= nil end
  local function pit(c) return c ~= 0 and lvl.cell[c] == 2 end
  -- 2) заглушка закреплена не на месте
  if st.fixed[qp] and not (st.pos[qp] == P and st.fixed[qt] and st.pos[qt] == T) then return true end
  -- ловит ли резьба деталь q в клетке c (закреплённые соседи с ответной резьбой)
  local R_ = { N = "V", V = "N" }
  local function caught(q, c)
    local ports = lvl.pieces[q].ports
    for d = 1, 4 do
      local th = ports[d]
      if th then
        local t = lvl.nb[c][d]
        local r = t ~= 0 and fixedAt[t]
        if r and lvl.pieces[r].ports[({ 3, 4, 1, 2 })[d]] == R_[th] then return true end
      end
    end
    return false
  end
  -- куда придёт деталь q, отпущенная в клетке c: клетка покоя, "caught:c" или 0 (смыло)
  local function fall(q, c)
    while true do
      if caught(q, c) then return c, true end
      local b = lvl.nb[c][3]
      if solid(b) then return c, false end
      if pit(b) then return 0, false end
      c = b
    end
  end
  local function pusherOK(t, c)
    if solid(t) or pit(t) then return false end
    for d = 1, 4 do
      local u = lvl.nb[t][d]
      if u ~= 0 and u ~= c and not solid(u) and not pit(u) then return true end
    end
    return false
  end
  local function canReach(q, c0, target)
    local seen, queue, h = { [c0] = true }, { c0 }, 1
    while h <= #queue do
      local c = queue[h]; h = h + 1
      if c == target then return true end
      for _, d in ipairs({ 2, 4 }) do
        local t = lvl.nb[c][d]
        local back = lvl.nb[c][d == 2 and 4 or 2]
        if t ~= 0 and not solid(t) and not pit(t) and pusherOK(back, c) then
          local r, fx = fall(q, t)
          if r ~= 0 then
            if r == target then return true end
            if not fx and not seen[r] then seen[r] = true; queue[#queue + 1] = r end
          end
        end
      end
    end
    return false
  end
  local function onSolid(c) return solid(lvl.nb[c][3]) end
  local paired = (not st.fixed[qt]) and (not st.fixed[qp]) and st.asm[qt] == st.asm[qp]
  if paired then
    -- 3) свинченная пара, которую уже нельзя сдвинуть ни влево, ни вправо
    local cells = { st.pos[qt], st.pos[qp] }
    local set = { [cells[1]] = true, [cells[2]] = true }
    if not (onSolid(cells[1]) or onSolid(cells[2])) then return false end
    for _, d in ipairs({ 2, 4 }) do
      local free, pusher = true, false
      for _, c in ipairs(cells) do
        local c2 = lvl.nb[c][d]
        if not set[c2] and solid(c2) then free = false end
        local back = lvl.nb[c][d == 2 and 4 or 2]
        if not set[back] and pusherOK(back, c) then pusher = true end
      end
      if free and pusher then return false end
    end
    return true
  end
  -- 1) одиночная свободная деталь на твёрдом, которой уже не попасть на место
  if not st.fixed[qt] and onSolid(st.pos[qt]) and not canReach(qt, st.pos[qt], T) then return true end
  if not st.fixed[qp] and onSolid(st.pos[qp]) and not canReach(qp, st.pos[qp], P) then return true end
  return false
end
return visibleLoss
