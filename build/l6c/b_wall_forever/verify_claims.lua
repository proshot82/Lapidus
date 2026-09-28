-- verify_claims.lua — проверка заявлений по b11 (скептик): ошибка из подсказки №1 и варианты абляции роли.
-- Печатает только метрики и да/нет, без порядка ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile("build/l6c/b_wall_forever/b11.lua")
local wide = dofile("build/l6c/b_wall_forever/verify_wide.lua")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local idx = {}
for i = 1, G.n do idx[G.keys[i]] = i end
local function tagpos(st, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return st.pos[q], st.fixed[q] end end end
local C = 2 * lvl.W + 6
-- 1) ошибка из подсказки №1: ищем среди соседей старта состояние «муфта в гнезде, ниппель наверху»
local s0 = R.newState(lvl)
local found = 0
for m = 1, 8 do
  local mm = R.MOVES[m]
  local ns = R.move(lvl, s0, mm.which, mm.dir)
  if ns then
    local c, f = tagpos(ns, "upc")
    if c == C and f then
      local i = idx[R.key(ns)]
      local pn = tagpos(ns, "pn")
      print(string.format("ошибка №1 с первого хода: в графе=%s, живое=%s, видимо(автор)=%s, видимо(шире)=%s, ниппель в ряду %d",
        tostring(i ~= nil), tostring(good[i] == 1), tostring(def.visibleLoss(lvl, ns)), tostring(wide.visibleLoss(lvl, ns)),
        math.floor((pn - 1) / lvl.W) + 1))
      found = found + 1
    end
  end
end
print("ходов со старта, ведущих к ошибке №1: " .. found)
-- 2) варианты абляции роли
local function run(name, filter)
  local G2 = SV.explore(lvl, 3000000, filter)
  print(string.format("абляция «%s»: %s (состояний %d)", name, G2.firstWin and ("РЕШАЕМ за " .. G2.depth[G2.firstWin]) or "нерешаем", G2.n))
  SV.freeGraph(G2)
end
local function pnq() for q, p in ipairs(lvl.pieces) do if p.tag == "pn" then return q end end end
local function upcq() for q, p in ipairs(lvl.pieces) do if p.tag == "upc" then return q end end end
local P, U = pnq(), upcq()
run("автора: ниппель не входит в гнездо и не падает сквозь него", def.ablations[1].filter)
run("узкая: ниппель не падает из гнезда вниз (горизонтально проходить можно)", function(l, st, ns)
  local a, b = st.pos[P], ns.pos[P]
  if a == C and b ~= C and b ~= 0 and (b - 1) % l.W + 1 == 6 and b > C then return false end
  if b ~= 0 and b > C and (b - 1) % l.W + 1 == 6 and a ~= 0 and a < C + l.W - 5 then return false end
  return true end)
run("ниппель не входит в гнездо вовсе", function(l, st, ns) return ns.pos[P] ~= C end)
run("муфта не встаёт в гнездо, пока ниппель не закреплён (порядок)", function(l, st, ns)
  if ns.pos[U] == C and ns.fixed[U] and not ns.fixed[P] then return false end return true end)
run("тело Лапидуса не входит в гнездо", function(l, st, ns)
  for _, c in ipairs(ns.body) do if c == C then return false end end return true end)
run("ниппель не спускается левым колодцем", function(l, st, ns)
  local b = ns.pos[P]; if b ~= 0 and (b - 1) % l.W + 1 == 2 and b > 3 * l.W then return false end return true end)
-- 3) скрытые тупики, соседние с кратчайшим путём, по шагам (автор / шире)
local function lostBy(d, st) for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end return d.visibleLoss(lvl, st) end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local ta, tw = {}, {}
for k = 1, #path - 1 do
  local s = path[k]; local na, nw = 0, 0
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if G.flag[j] == 0 and good[j] ~= 1 then local st = R.decode(lvl, G.keys[j])
      if not lostBy(def, st) then na = na + 1 end; if not lostBy(wide, st) then nw = nw + 1 end end
  end
  ta[#ta + 1] = na; tw[#tw + 1] = nw
end
print("скрытых соседей у пути по шагам (автор): " .. table.concat(ta, ""))
print("скрытых соседей у пути по шагам (шире):  " .. table.concat(tw, ""))
-- 4) откуда входят в тупик «не тем концом» (конфигурация: обе детали закреплены)
local entries, minD = 0, 1e9
for i = 1, G.n do if good[i] == 1 and G.flag[i] == 0 then
  for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
    local j = G.edges.p[e]
    if good[j] ~= 1 and G.flag[j] == 0 then local st = R.decode(lvl, G.keys[j])
      local _, fp = tagpos(st, "pn"); local _, fu = tagpos(st, "upc")
      if fp and fu and not lostBy(def, st) then entries = entries + 1; if G.depth[i] < minD then minD = G.depth[i] end end end
  end
end end
print(string.format("входов в тупик «не тем концом»: %d, ближайший с глубины %d от старта", entries, minD))
SV.freeGraph(G)
