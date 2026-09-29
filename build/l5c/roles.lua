-- build/l5c/roles.lua файл.lua — абляция роли и контрольные фильтры (узость фильтра роли). Решений не печатает.
-- Для каждого фильтра: решаем ли и за сколько, сколько переходов кратчайшего пути он запрещает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local qt, qp, src
for q, p in ipairs(lvl.pieces) do if p.what == "tee" then qt = q elseif p.what == "plug" then qp = q elseif p.source then src = q end end
local sd
for d = 1, 4 do if lvl.pieces[src].ports[d] then sd = d end end
local T = lvl.nb[lvl.pieces[src].start][sd]
local P = lvl.nb[T][4]
local U = lvl.nb[T][1]
local function onPiece(ns, q, fixedWanted)
  local c = ns.pos[q]
  if c == 0 or ns.fixed[q] ~= fixedWanted then return false end
  local above = lvl.nb[c][1]
  for _, b in ipairs(ns.body) do if b == above then return true end end
  return false
end
local filters = {
  { "РОЛЬ (широко): Лапидус не стоит на свободной заглушке", function(l, s, ns) return not onPiece(ns, qp, false) end },
  { "РОЛЬ (узко): стоя на свободной заглушке, не подниматься выше досягаемого с пола", function(l, s, ns)
      if not onPiece(ns, qp, false) then return true end
      local pr = math.floor((ns.pos[qp] - 1) / lvl.W) + 1
      for _, b in ipairs(ns.body) do if math.floor((b - 1) / lvl.W) + 1 <= pr - 4 then return false end end
      return true end },
  { "контроль: Лапидус не стоит на закреплённой заглушке", function(l, s, ns) return not onPiece(ns, qp, true) end },
  { "контроль: заглушка не в гнезде раньше тройника", function(l, s, ns)
      return not (ns.pos[qp] == P and not (ns.fixed[qt] and ns.pos[qt] == T)) end },
  { "контроль: тройник не на сушителе", function(l, s, ns)
      return not (ns.fixed[qt] and ns.pos[qt] ~= T) end },
  { "контроль: Лапидус не заходит в гнездо заглушки", function(l, s, ns)
      for _, b in ipairs(ns.body) do if b == P then return false end end; return true end },
}
local G = SV.explore(lvl, 3000000)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
print("полный граф: состояний " .. G.n .. ", ходов " .. G.depth[G.firstWin])
for _, f in ipairs(filters) do
  local onPath = 0
  for k = 2, #path do
    local a, b = R.decode(lvl, G.keys[path[k - 1]]), R.decode(lvl, G.keys[path[k]])
    if not f[2](lvl, a, b) then onPath = onPath + 1 end
  end
  local G2 = SV.explore(lvl, 3000000, f[2])
  print(string.format("%-58s состояний %5d, %s; запрещает переходов кратчайшего пути: %d", f[1], G2.n,
    G2.firstWin and ("РЕШАЕМ за " .. G2.depth[G2.firstWin]) or "нерешаем", onPath))
  SV.freeGraph(G2)
end
SV.freeGraph(G)
