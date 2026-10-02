-- abl10.lua — фильтры ролей для b10 (подставляются в файл уровня). Проверка: luajit flt.lua файл имя...
local M = {}
local function Qs(lvl) local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end; return Q end
local function colx(lvl) for _, p in ipairs(lvl.pieces) do if p.source then return (p.start - 1) % lvl.W + 1, math.floor((p.start - 1) / lvl.W) + 1 end end end
-- роль: фонтан глотает лишнюю муфту (муфта не бывает в клетках струи над стояком)
function M.noSwallow(lvl, st, ns)
  local Q = Qs(lvl); local sx, sy = colx(lvl)
  local c = ns.pos[Q.cpl]; if c == 0 then return true end
  local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
  if x == sx and y < sy and y >= sy - lvl.R then return false end
  return true
end
-- роль: фонтан держит переходник на весу (переходник не бывает на верхушке фонтана, пока не закреплён)
function M.noHoverAdp(lvl, st, ns)
  local Q = Qs(lvl); local sx, sy = colx(lvl)
  local c = ns.pos[Q.adp]; if c == 0 or ns.fixed[Q.adp] then return true end
  local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
  if x == sx and y == sy - lvl.R - 1 then return false end
  return true
end
-- роль: фонтан — лифт для Лапидуса (Лапидус не бывает в клетках струи, не будучи прикручен)
function M.noRide(lvl, st, ns)
  local R = require("core.rules")
  local sx, sy = colx(lvl)
  local piece = R.occupancy(ns)
  if R.endScrew(lvl, ns, piece, "head") or R.endScrew(lvl, ns, piece, "heel") then return true end
  for _, c in ipairs(ns.body) do
    local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
    if x == sx and y < sy and y >= sy - lvl.R then return false end
  end
  return true
end
-- контроль: переходник попадает в ванну только при глушении (сверху не проталкивать)
function M.dropOnly(lvl, st, ns)
  local Q = Qs(lvl)
  if ns.fixed[Q.adp] and not ns.fixed[Q.elb] then return false end
  return true
end
-- контроль: муфту не сбивают в карман справа (только иначе)
function M.cplNotRight(lvl, st, ns)
  local Q = Qs(lvl); local sx = colx(lvl)
  local c = ns.pos[Q.cpl]; if c == 0 then return true end
  return (c - 1) % lvl.W + 1 <= sx
end
-- точные версии (28.09): муфта не бывает ВНУТРИ действующей струи (проглочена)
function M.noSwallowJet(lvl, st, ns)
  local R = require("core.rules")
  local Q = Qs(lvl)
  local c = ns.pos[Q.cpl]; if c == 0 then return true end
  for _, j in ipairs(R.jets(lvl, ns)) do for _, t in ipairs(j.cells) do if t == c then return false end end end
  return true
end
-- переходник (незакреплённый) не бывает на опоре струи вверх: в столбе или на клетке над верхушкой
function M.noRideAdpJet(lvl, st, ns)
  local R = require("core.rules")
  local Q = Qs(lvl)
  local c = ns.pos[Q.adp]; if c == 0 or ns.fixed[Q.adp] then return true end
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == 1 and #j.cells > 0 then
      for _, t in ipairs(j.cells) do if t == c then return false end end
      if lvl.nb[j.cells[#j.cells]][1] == c then return false end
    end
  end
  return true
end
-- угольник (незакреплённый) не бывает на опоре струи вверх
function M.noRideElbJet(lvl, st, ns)
  local R = require("core.rules")
  local Q = Qs(lvl)
  local c = ns.pos[Q.elb]; if c == 0 or ns.fixed[Q.elb] then return true end
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == 1 and #j.cells > 0 then
      for _, t in ipairs(j.cells) do if t == c then return false end end
      if lvl.nb[j.cells[#j.cells]][1] == c then return false end
    end
  end
  return true
end
-- муфта (после старта) не бывает на опоре струи вверх вовсе: ни внутри, ни сверху
function M.noCplOnJet(lvl, st, ns)
  local R = require("core.rules")
  local Q = Qs(lvl)
  local c = ns.pos[Q.cpl]; if c == 0 then return true end
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == 1 and #j.cells > 0 then
      for _, t in ipairs(j.cells) do if t == c then return false end end
      if lvl.nb[j.cells[#j.cells]][1] == c then return false end
    end
  end
  return true
end
return M
