-- abl.lua файл.lua имя_фильтра — решаемость уровня с фильтром ходов (для абляций и контролей). Без ходов.
-- Фильтры: nopress (угольник не вдавливают сверху: нельзя войти в первую клетку фонтана из клетки над ней),
--          noride (детали не катаются: деталь не может оказаться выше своей стартовой строки),
--          nohose (нет брандспойта: запрещены состояния, где мокрый Лапидус со свободным концом),
--          nolapride (Лапидус не катается на фонтане: ни одна клетка тела не в столбе струи вверх),
--          noearly (нельзя глушить фонтан, пока Лапидус в подсобке: состояние «угольник закреплён, Лапидус левее x0»).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local W = lvl.W
local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
local tag = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tag[p.tag] = q end; if p.what == "tee" then tag.tee = q end end
local tee = lvl.pieces[tag.tee].start
local tx, ty = xy(tee)
local filters = {}
filters.nopress = function(l, st, ns)
  local q = tag.e
  local a, b = st.pos[q], ns.pos[q]
  if a ~= 0 and b ~= 0 then
    local ax, ay = xy(a); local bx, by = xy(b)
    if ax == tx and bx == tx and by == ty - 1 and ay == ty - 2 then return false end
  end
  return true
end
filters.onlyright = function(l, st, ns) -- угольник входит в первую клетку фонтана только справа (со стороны ванны)
  local q = tag.e
  local a, b = st.pos[q], ns.pos[q]
  if a ~= 0 and b ~= 0 and b == lvl.nb[tee][R.UP] and a ~= b then
    local ax, ay = xy(a)
    if not (ax == tx + 1 and ay == ty - 1) then return false end
  end
  return true
end
filters.nolid = function(l, st, ns) -- нельзя держать деталь в первой клетке фонтана (крышка из Лапидуса)
  if ns.dead then return true end
  local c1 = lvl.nb[tee][R.UP]
  for q, p in ipairs(lvl.pieces) do if p.movable and ns.pos[q] == c1 and not ns.fixed[q] then return false end end
  return true
end
filters.noride = function(l, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and ns.pos[q] ~= 0 then
      local _, y = xy(ns.pos[q]); local _, y0 = xy(p.start)
      if y < y0 then return false end
    end
  end
  return true
end
filters.nohose = function(l, st, ns)
  if ns.dead then return true end
  local w = R.water(lvl, ns)
  if w.lapWet and not (w.headQ and w.heelQ) then return false end
  return true
end
filters.nolapride = function(l, st, ns)
  if ns.dead then return true end
  local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  for _, c in ipairs(ns.body) do if col[c] then return false end end
  return true
end
local f = assert(filters[arg[2]], "нет фильтра")
local G = SV.explore(lvl, 3000000, f)
if arg[3] == "moves" and G.firstWin then -- ТОЛЬКО вывод инструмента
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, G.pmove[x]); x = G.parent[x] end
  local A = { "^", ">", "v", "<" }
  local t = {}
  for _, m in ipairs(path) do local mm = R.MOVES[m]; t[#t + 1] = (mm.which == "head" and "H" or "F") .. A[mm.dir] end
  print(table.concat(t, " "))
end
print(string.format("%s [%s]: %s (состояний %d%s)", arg[1]:match("([^/]+)$"), arg[2], G.firstWin and "решаем" or "НЕРЕШАЕМ", G.n,
  G.firstWin and (", ходов " .. G.depth[G.firstWin]) or ""))
SV.freeGraph(G)
