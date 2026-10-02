-- verify_abl.lua файл.lua — скептик кв. 7 (28.09): абляции роли автора и контрольные фильтры.
-- Для каждого фильтра: решаем ли (и за сколько), размер графа, сколько переходов кратчайшего пути он запрещает.
-- Контроли обязаны оставаться решаемыми: они запрещают ошибки или соседние приёмы, а не «ага».
-- Печатает только числа.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local srcC
for _, p in ipairs(lvl.pieces) do if p.source then srcC = p.start end end
local sx = (srcC - 1) % lvl.W + 1
local I = function(x, y) return R.idx(lvl, x, y) end
local function inJet(st, c)
  if c == 0 then return false end
  for _, j in ipairs(R.jets(lvl, st)) do for _, t in ipairs(j.cells) do if t == c then return true end end end
  return false
end
local F = {}
for _, ab in ipairs(def.ablations or {}) do if ab.filter then F[#F + 1] = { "автор: " .. ab.name, ab.filter, false } end end
local C = {
  { "контроль: муфта никогда не в углу кармана", function(l, s, ns) return ns.pos[Q.cpl] ~= I(8, 6) end },
  { "контроль: муфта никогда не вкручена", function(l, s, ns) return not ns.fixed[Q.cpl] end },
  { "контроль: переходник никогда не в кармане", function(l, s, ns) local c = ns.pos[Q.adp]; return c == 0 or ns.fixed[Q.adp] or (c - 1) % l.W + 1 <= sx end },
  { "контроль: угольник никогда не внутри действующей струи", function(l, s, ns) return ns.fixed[Q.elb] or not inJet(ns, ns.pos[Q.elb]) end },
  { "контроль: переходник никогда не внутри действующей струи", function(l, s, ns) return ns.fixed[Q.adp] or not inJet(ns, ns.pos[Q.adp]) end },
  { "контроль: без брандспойта", function(l, s, ns)
      local w = R.status(l, ns)
      return not (w.lapWet and not w.win and (w.headQ == nil or w.heelQ == nil)) end },
  { "контроль: Лапидус не катается на фонтане", function(l, s, ns)
      local piece = R.occupancy(ns)
      if R.endScrew(l, ns, piece, "head") or R.endScrew(l, ns, piece, "heel") then return true end
      for _, c in ipairs(ns.body) do if inJet(ns, c) then return false end end
      return true end },
  { "контроль: фонтан не глушат сверху (толчком вниз)", function(l, s, ns)
      local first = l.nb[srcC][1]
      return not (ns.fixed[Q.elb] and not s.fixed[Q.elb] and s.pos[Q.elb] == l.nb[first][1]) end },
}
for _, c in ipairs(C) do F[#F + 1] = { c[1], c[2], true } end
-- кратчайший путь без фильтров
local G0 = SV.explore(lvl, 3000000)
local path, x = {}, G0.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G0.parent[x] end
table.insert(path, 1, 1)
local PS = {}
for k, id in ipairs(path) do PS[k] = R.decode(lvl, G0.keys[id]) end
print(string.format("без фильтров: состояний %d, решаем за %d", G0.n, G0.depth[G0.firstWin]))
SV.freeGraph(G0)
for _, f in ipairs(F) do
  local G = SV.explore(lvl, 3000000, f[2])
  local blocked = 0
  for k = 1, #PS - 1 do if not f[2](lvl, PS[k], PS[k + 1]) then blocked = blocked + 1 end end
  print(string.format("%-58s состояний %6d, %s; запрещает переходов кратчайшего пути: %d",
    f[1], G.n, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ", blocked))
  SV.freeGraph(G)
end
