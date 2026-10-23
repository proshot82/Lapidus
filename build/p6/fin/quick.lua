-- быстрый замер с проверкой связи: ходов, состояний, ширина (кол-во кратчайших), «эстафета» обязательна?
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
for i = 1, #arg do
  local def = dofile(arg[i])
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 2000000)
  if G and G.firstWin then
    local mv, n = G.depth[G.firstWin], G.n
    SV.freeGraph(G)
    local cq, nq
    for q, p in ipairs(lvl.pieces) do if p.tag == "cpl" then cq = q elseif p.tag == "nip" then nq = q end end
    local G2 = SV.explore(lvl, 2000000, function(l, st, ns)
      local a, c = ns.pos[nq], ns.pos[cq]
      if a == 0 or c == 0 or ns.fixed[cq] then return true end
      return l.nb[a][3] ~= c end)
    local forced = not (G2 and G2.firstWin)
    if G2 then SV.freeGraph(G2) end
    print(string.format("%s ходов %d сост %d эстафета %s", arg[i], mv, n, forced and "ОБЯЗАТЕЛЬНА" or "нет"))
  else print(arg[i] .. " нереш"); if G then SV.freeGraph(G) end end
  io.stdout:flush()
end
