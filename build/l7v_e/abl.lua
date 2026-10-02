-- build/l7v_e/abl.lua файл.lua — дополнительные узкие абляции (фильтры ходов): решаем ли уровень и за сколько.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local tee; for q, p in ipairs(lvl.pieces) do if p.what == "tee" then tee = q end end
local function fountain(ns)
  local col = {}
  for _, j in ipairs(R.jets(lvl, ns)) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  return col
end
local function heldInfo(ns)
  if ns.dead then return nil end
  local col = fountain(ns); local body = {}; for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and col[c] and body[lvl.nb[c][1]] then return q end end
end
local function bodyHas(ns, f) for _, c in ipairs(ns.body) do local x, y = R.xy(lvl, c); if f(x, y) then return true end end end
local function y(c) local _, yy = R.xy(lvl, c); return yy end
local base = lvl.nb[lvl.pieces[tee].start][1]
local filters = {
  { "держать деталь можно только у верхушки (нет удержания, когда тело не выше ряда 3)", function(l, st, ns) local q = heldInfo(ns); return not q or bodyHas(ns, function(x, yy) return yy <= 3 end) end },
  { "держать деталь можно только у основания (нет удержания, когда тело касается ряда ≤3)", function(l, st, ns) local q = heldInfo(ns); return not q or not bodyHas(ns, function(x, yy) return yy <= 3 end) end },
  { "держать можно только угольник", function(l, st, ns) local q = heldInfo(ns); return not q or q == Q.elb end },
  { "держать можно только пробку", function(l, st, ns) local q = heldInfo(ns); return not q or q == Q.plug end },
  { "пробка никогда не выше ряда 5 (не катается)", function(l, st, ns) return ns.dead or ns.pos[Q.plug] == 0 or y(ns.pos[Q.plug]) >= 5 end },
  { "пробка никогда не выше ряда 4", function(l, st, ns) return ns.dead or ns.pos[Q.plug] == 0 or y(ns.pos[Q.plug]) >= 4 end },
  { "прикрученный Лапидус не обрывает фонтан (нет состояний с якорем и телом в клетках над тройником до ряда 4, пока тройник открыт вверх)", function(l, st, ns)
      if ns.dead or ns.fixed[Q.elb] then return true end
      local w = R.status(lvl, ns)
      local anch = false
      local ei = R.endInfo and nil
      -- якорь: см. R.water (headQ/heelQ)
      local piece = R.occupancy(ns); local ww = R.water(lvl, ns, piece)
      if not (ww.headQ or ww.heelQ) then return true end
      return not bodyHas(ns, function(x, yy) return x == 5 and yy >= 4 and yy <= 6 end) end },
  { "Лапидус не заходит в нишу", function(l, st, ns) return ns.dead or not bodyHas(ns, function(x, yy) return x == 4 and yy == 3 end) end },
  { "Лапидус не заходит в подсобку (3..4,5)", function(l, st, ns) return ns.dead or not bodyHas(ns, function(x, yy) return x <= 4 and yy == 5 end) end },
  { "Лапидус не поднимается выше ряда 4", function(l, st, ns) return ns.dead or not bodyHas(ns, function(x, yy) return yy <= 3 end) end },
}
for _, f in ipairs(filters) do
  local G = SV.explore(lvl, 3000000, f[2])
  local r = (G and G.firstWin) and ("РЕШАЕМ за " .. G.depth[G.firstWin]) or "нерешаем"
  print(string.format("%s → %s", f[1], r))
  if G then SV.freeGraph(G) end
end
