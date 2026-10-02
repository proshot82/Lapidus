-- verify2_engine.lua файл.lua [вариант ...] — держится ли решение на тонкостях движка напора, которые игрок может
-- не вывести из паспорта и §4. Для каждого варианта правил (копия core/rules.lua с одной заменой; сам движок не
-- меняется): проходит ли кратчайшее решение исходного движка (печатается только «да» или номер шага, где сломалось)
-- и решаем ли уровень вообще (ходов, состояний). Решений и кадров не печатает.
package.path = "./?.lua;" .. package.path
local R0 = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local f = assert(io.open("core/rules.lua")); local SRC = f:read("*a"); f:close()

local function replace(src, old, new)
  local a, b = src:find(old, 1, true)
  assert(a, "patch anchor not found: " .. old:sub(1, 60))
  assert(not src:find(old, b + 1, true), "patch anchor not unique: " .. old:sub(1, 60))
  return src:sub(1, a - 1) .. new .. src:sub(b + 1)
end

local SETTLE_OLD = [=[
    local c1 = threads(lvl, st, piece)
    local c2, c3 = false, false
    local sup = nil
    if lvl.R > 0 then
      local w = R.water(lvl, st, piece)
      local jets, anchored = computeJets(lvl, st, piece, bodyAt, w)
      sup = jetSupport(lvl, jets)
      c2 = applyJets(lvl, st, jets, anchored)
      if c2 then wash(lvl, st) end
    end
    if not st.dead then
      c3 = gravity(lvl, st, sup)
      if c3 then wash(lvl, st) end
    end
]=]

local VARIANTS = {
  { id = "gravity_first", name = "в шаге цикла гравитация раньше струй",
    patch = function(s) return replace(s, SETTLE_OLD, [=[
    local c1 = threads(lvl, st, piece)
    local c2, c3 = false, false
    local sup = nil
    if lvl.R > 0 then
      local w = R.water(lvl, st, piece)
      local jets = computeJets(lvl, st, piece, bodyAt, w)
      sup = jetSupport(lvl, jets)
    end
    c3 = gravity(lvl, st, sup)
    if c3 then wash(lvl, st) end
    if lvl.R > 0 and not st.dead then
      piece, bodyAt = occupancy(st)
      local w = R.water(lvl, st, piece)
      local jets, anchored = computeJets(lvl, st, piece, bodyAt, w)
      c2 = applyJets(lvl, st, jets, anchored)
      if c2 then wash(lvl, st) end
    end
]=]) end },
  { id = "jets_before_threads", name = "струя раньше резьбы (нет правила «резьба сильнее струи»)",
    patch = function(s) return replace(s, SETTLE_OLD, [=[
    local c1 = false
    local c2, c3 = false, false
    local sup = nil
    if lvl.R > 0 then
      local w = R.water(lvl, st, piece)
      local jets, anchored = computeJets(lvl, st, piece, bodyAt, w)
      sup = jetSupport(lvl, jets)
      c2 = applyJets(lvl, st, jets, anchored)
      if c2 then wash(lvl, st) end
    end
    piece, bodyAt = occupancy(st)
    c1 = threads(lvl, st, piece)
    if not st.dead then
      c3 = gravity(lvl, st, sup)
      if c3 then wash(lvl, st) end
    end
]=]) end },
  { id = "lap_immune", name = "струя не действует на Лапидуса (не толкает и не держит)",
    patch = function(s)
      s = replace(s, "      if (not anchored) and (not seenL) and bodyAt[c] then", "      if false then")
      s = replace(s, [=[
        local c = b[i]
        local s = (sup ~= nil) and (sup[c] == true)]=], [=[
        local c = b[i]
        local s = false]=])
      return s
    end },
  { id = "lap_not_pushed", name = "струя держит Лапидуса, но не толкает",
    patch = function(s) return replace(s, "      if (not anchored) and (not seenL) and bodyAt[c] then", "      if false then") end },
  { id = "no_top_cell", name = "столб держит только внутри струи (без клетки над верхушкой)",
    patch = function(s) return replace(s, [=[
      local top = lvl.nb[j.cells[#j.cells]][UP]
      if top ~= 0 then sup[top] = true end]=], "") end },
  { id = "jet_stops_at_piece", name = "струю останавливает первая подвижная деталь (её толкает, дальше не идёт)",
    patch = function(s) return replace(s, "      cells[#cells + 1] = t\n", "      cells[#cells + 1] = t\n      if r then break end\n") end },
  { id = "jet_no_chain", name = "струя толкает только деталь в струе, стопку над ней — нет",
    patch = function(s)
      s = replace(s, "local function applyJets(lvl, st, jets, anchored)", [=[
local function pushSolo(lvl, st, piece, bodyAt, a0, d)
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  for q = 1, #pos do
    local c = pos[q]
    if c ~= 0 and not fixed[q] and asm[q] == a0 then
      local t = lvl.nb[c][d]
      if t == 0 or lvl.cell[t] == WALL or bodyAt[t] then return false end
      local r = piece[t]
      if r and (fixed[r] or asm[r] ~= a0) then return false end
    end
  end
  for q = 1, #pos do local c = pos[q]; if c ~= 0 and not fixed[q] and asm[q] == a0 then pos[q] = lvl.nb[c][d] end end
  return true
end
local function applyJets(lvl, st, jets, anchored)]=])
      return replace(s, "      if pushAssemblies(lvl, st, piece, bodyAt, B.a, B.d) then moved = true end",
                        "      if pushSolo(lvl, st, piece, bodyAt, B.a, B.d) then moved = true end")
    end },
  { id = "bottom_up", name = "толчки внутри шага снизу вверх (а не сверху вниз)",
    patch = function(s) return replace(s, "tsort(bodies, function(x, y) return x.top < y.top end)", "tsort(bodies, function(x, y) return x.top > y.top end)") end },
  { id = "horizontal_wins", name = "при толчках по двум осям действует горизонтальный",
    patch = function(s) return replace(s, [=[
  if vy < 0 then return UP elseif vy > 0 then return DOWN
  elseif vx > 0 then return RIGHT elseif vx < 0 then return LEFT end]=], [=[
  if vx > 0 then return RIGHT elseif vx < 0 then return LEFT
  elseif vy < 0 then return UP elseif vy > 0 then return DOWN end]=]) end },
}

-- кратчайшее решение исходного движка (в памяти, наружу не печатается)
local lvl0 = R0.compile(def)
local G0 = SV.explore(lvl0, 3000000)
local moves = {}
do local x = G0.firstWin; while x ~= 1 do table.insert(moves, 1, G0.pmove[x]); x = G0.parent[x] end end
print(string.format("исходный движок: кратчайшее решение %d ходов, состояний %d", #moves, G0.n))
SV.freeGraph(G0)

local function bfs(R, lvl, cap)
  local s0 = R.newState(lvl)
  local k0 = R.key(s0)
  local index, keys, depth = { [k0] = 1 }, { k0 }, { 0 }
  local win = nil
  local unstable = 0
  if R.isWin(lvl, s0) then return 0, 1, 0 end
  local qi = 1
  while qi <= #keys do
    local id = qi; qi = qi + 1
    local st = R.decode(lvl, keys[id])
    if not st.dead and not R.isWin(lvl, st) then
      for m = 1, 8 do
        local mm = R.MOVES[m]
        local ns, _, stable = R.move(lvl, st, mm.which, mm.dir)
        if ns then
          if stable == false then unstable = unstable + 1 end
          local kk = R.key(ns)
          if not index[kk] then
            local nid = #keys + 1
            if nid > cap then return nil, nid, unstable end
            keys[nid] = kk; index[kk] = nid; depth[nid] = depth[id] + 1
            if not win and not ns.dead and R.isWin(lvl, ns) then win = depth[nid] end
          end
        end
      end
    end
  end
  return win, #keys, unstable
end

local want = {}
for i = 2, #arg do want[arg[i]] = true end
for _, v in ipairs(VARIANTS) do
  if next(want) == nil or want[v.id] then
    local src = v.patch(SRC)
    local chunk = assert(loadstring(src, "rules_" .. v.id))
    local R1 = chunk()
    local ok, lvl1 = pcall(R1.compile, def)
    local line = v.name .. ": "
    if not ok then line = line .. "ошибка компиляции" else
      local okInit, st = pcall(R1.newState, lvl1)
      if not okInit then line = line .. "стартовая раскладка не устаканивается" else
        local broke = nil
        for i, m in ipairs(moves) do
          local mm = R1.MOVES[m]
          local ns = R1.move(lvl1, st, mm.which, mm.dir)
          if not ns or ns.dead then broke = i; break end
          st = ns
        end
        if broke then line = line .. string.format("авторское решение ломается на ходу %d из %d", broke, #moves)
        elseif not R1.isWin(lvl1, st) then line = line .. "авторское решение доходит до конца без победы"
        else line = line .. "авторское решение проходит" end
        local win, n, unst = bfs(R1, lvl1, 3000000)
        line = line .. string.format("; уровень %s (состояний %d%s)", win and ("решаем за " .. win .. " ходов") or "НЕРЕШАЕМ", n,
          unst > 0 and (", неустойчивых ходов " .. unst) or "")
      end
    end
    print(line)
    io.stdout:flush()
  end
end
