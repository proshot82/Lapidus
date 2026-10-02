-- build/l7v_d/filters.lua [файл уровня] — контрольные фильтры (должны оставаться решаемыми) и дополнительные абляции
-- роли (узкие: запрещают ровно один приём). Только решаемость и метрики, без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l7c/d_tee_lift/L7D.lua")
local lvl = R.compile(def)
local function find(what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local QE, QP = find("elbow"), find("plug")
local function xy(c) return R.xy(lvl, c) end
local function idx(x, y) return (y - 1) * lvl.W + x end
local function bodySet(st) local b = {} for _, c in ipairs(st.body) do b[c] = true end return b end
local function anchored(st) local piece = R.occupancy(st) return R.endScrew(lvl, st, piece, "head") or R.endScrew(lvl, st, piece, "heel") end
-- клетки столба фонтана тройника (струя вверх), если он бьёт
local function fountainCells(st)
  local col = {}
  for _, j in ipairs(R.jets(lvl, st)) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  return col
end

local F = {}
-- контроли: ожидаем РЕШАЕМ
F[#F + 1] = { name = "К1 в нишу (4,3) не заходить", ctrl = true, f = function(lvl, st, ns)
  for _, c in ipairs(ns.body) do if c == idx(4, 3) then return false end end return true end }
F[#F + 1] = { name = "К2 в корыто (ряд 8) не спускаться", ctrl = true, f = function(lvl, st, ns)
  for _, c in ipairs(ns.body) do local x, y = xy(c); if y == 8 then return false end end return true end }
F[#F + 1] = { name = "К3 правее x=8 не ходить", ctrl = true, f = function(lvl, st, ns)
  for _, c in ipairs(ns.body) do local x = xy(c); if x > 8 then return false end end return true end }
F[#F + 1] = { name = "К4 голова никогда не в столбе фонтана (пробка только ногами)", ctrl = true, f = function(lvl, st, ns)
  if ns.dead then return true end
  local col = fountainCells(ns); return not col[ns.body[#ns.body]] end }
F[#F + 1] = { name = "К5 ноги никогда не в столбе фонтана (пробка только головой)", ctrl = true, f = function(lvl, st, ns)
  if ns.dead then return true end
  local col = fountainCells(ns); return not col[ns.body[1]] end }
F[#F + 1] = { name = "К6 угольник не выше ряда 3 (в (5,2) не задирать)", ctrl = true, f = function(lvl, st, ns)
  local c = ns.pos[QE]; if c == 0 then return true end local x, y = xy(c); return y >= 3 end }
F[#F + 1] = { name = "К7 длина не больше 4", ctrl = true, f = function(lvl, st, ns) return #ns.body <= 4 end }
F[#F + 1] = { name = "К8 Лапидус никогда не прикручен к тройнику (ноги в (5,6) вниз)", ctrl = true, f = function(lvl, st, ns)
  if ns.dead then return true end
  local piece = R.occupancy(ns); local q = R.endScrew(lvl, ns, piece, "heel"); return not (q and lvl.pieces[q].what == "tee") end }
-- абляции роли (узкие): ожидаем НЕРЕШАЕМ, если приём обязателен
F[#F + 1] = { name = "А1 ничего не держать под телом в столбе (деталь в столбе, над ней клетка Лапидуса)", ctrl = false, f = function(lvl, st, ns)
  if ns.dead then return true end
  local col = fountainCells(ns); local b = bodySet(ns)
  for q, p in ipairs(lvl.pieces) do if p.movable and ns.pos[q] ~= 0 and not ns.fixed[q] and col[ns.pos[q]] and b[lvl.nb[ns.pos[q]][1]] then return false end end
  return true end }
F[#F + 1] = { name = "А2 заглушку под телом не держать", ctrl = false, f = function(lvl, st, ns)
  if ns.dead then return true end
  local col = fountainCells(ns); local b = bodySet(ns); local c = ns.pos[QP]
  return not (c ~= 0 and not ns.fixed[QP] and col[c] and b[lvl.nb[c][1]]) end }
F[#F + 1] = { name = "А3 угольник под телом не держать", ctrl = false, f = function(lvl, st, ns)
  if ns.dead then return true end
  local col = fountainCells(ns); local b = bodySet(ns); local c = ns.pos[QE]
  return not (c ~= 0 and not ns.fixed[QE] and col[c] and b[lvl.nb[c][1]]) end }
F[#F + 1] = { name = "А4 Лапидус не поднимается фонтаном (ни одна клетка тела не выше ряда 5, пока не прикручен угольник)", ctrl = false, f = function(lvl, st, ns)
  if ns.dead or ns.fixed[QE] then return true end
  for _, c in ipairs(ns.body) do local x, y = xy(c); if y <= 4 then return false end end return true end }
F[#F + 1] = { name = "А5 угольник никогда не выше ряда 4 (без езды на фонтане, но качаться в (5,5) можно)", ctrl = false, f = function(lvl, st, ns)
  local c = ns.pos[QE]; if c == 0 then return true end local x, y = xy(c); return y >= 5 end }
F[#F + 1] = { name = "А6 неприкрученного Лапидуса струя вбок не толкает (ход отвергается, если тело сдвинулось струёй вбок)", ctrl = false, f = function(lvl, st, ns)
  -- приближение: тело не может оказаться в клетках боковой струи угольника/тройника неприкрученным
  if ns.dead then return true end
  if anchored(ns) then return true end
  local b = bodySet(ns)
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir ~= R.UP and not j.lapidus then for _, c in ipairs(j.cells) do if b[c] then return false end end end end
  return true end }
F[#F + 1] = { name = "А7 в клетку (6,6) тело не заходит (финал только через ряд 6 справа)", ctrl = false, f = function(lvl, st, ns)
  for _, c in ipairs(ns.body) do if c == idx(6, 6) then return false end end return true end }
F[#F + 1] = { name = "А8 заглушка не бывает в (5,6) незакреплённой (в основание фонтана не заводить)", ctrl = false, f = function(lvl, st, ns)
  return not (ns.pos[QP] == idx(5, 6) and not ns.fixed[QP]) end }
F[#F + 1] = { name = "А9 заглушка в (6,7) только сверху (в (6,6) она не бывает)", ctrl = false, f = function(lvl, st, ns)
  return ns.pos[QP] ~= idx(6, 6) end }
F[#F + 1] = { name = "А10 угольник в (5,6) не вдавливать сверху (угольник не бывает в (5,4)/(5,5) незакреплённым)", ctrl = false, f = function(lvl, st, ns)
  local c = ns.pos[QE]; return not ((c == idx(5, 4) or c == idx(5, 5)) and not ns.fixed[QE]) end }

for _, fl in ipairs(F) do
  local G = SV.explore(lvl, 3000000, fl.f)
  local res
  if not G then res = "CAP" elseif G.firstWin then res = string.format("РЕШАЕМ, ходов %d, состояний %d", G.depth[G.firstWin], G.n) else res = string.format("нерешаем (состояний %d)", G.n) end
  print(string.format("%-92s %s  %s", fl.name, fl.ctrl and "[контроль]" or "[абляция] ", res))
  SV.freeGraph(G)
end
