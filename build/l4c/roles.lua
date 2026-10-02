-- build/l4c/roles.lua файл.lua — дополнительные контрольные фильтры для абляций роли (узость фильтра «по одной нельзя»).
-- Печатает для каждого фильтра: размер графа, решаем ли и за сколько, сколько состояний кратчайшего пути он запрещает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local qc, qn
for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end end
local W = lvl.W
local function at(x, y) return (y - 1) * W + x end
local pocket = { [at(2, 4)] = true, [at(2, 5)] = true, [at(3, 5)] = true }
local oneByOne
for _, a in ipairs(def.ablations) do if a.filter then oneByOne = a.filter end end
local filters = {
  { "РОЛЬ: по одной нельзя (муфта в шахте, ниппель ещё свободен)", oneByOne },
  { "контроль: сборки вне шахты не бывает", function(l, s, ns)
      return not (ns.pos[qc] ~= 0 and ns.pos[qn] ~= 0 and ns.asm[qc] == ns.asm[qn] and not ns.fixed[qc]) end },
  { "контроль: ниппель не вталкивает муфту (без толчка цепочкой)", function(l, s, ns)
      return not (not s.fixed[qc] and not s.fixed[qn] and s.pos[qc] ~= ns.pos[qc] and s.pos[qn] ~= ns.pos[qn]) end },
  { "контроль: Лапидус не заходит в кладовку", function(l, s, ns)
      for _, c in ipairs(ns.body) do if pocket[c] then return false end end
      return true end },
  { "контроль: ниппель не падает влево от машинки", function(l, s, ns)
      local n = ns.pos[qn]; return n == 0 or (n - 1) % W + 1 ~= 4 end },
  { "контроль: муфта не бывает под мостом (x=6), пока ниппель на машинке", function(l, s, ns)
      return not (ns.pos[qc] == at(6, 5) and ns.pos[qn] == at(5, 3)) end },
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
  print(string.format("%-62s состояний %5d, %s; запрещает переходов кратчайшего пути: %d", f[1], G2.n,
    G2.firstWin and ("РЕШАЕМ за " .. G2.depth[G2.firstWin]) or "нерешаем", onPath))
  SV.freeGraph(G2)
end
SV.freeGraph(G)
