-- проверка связи: запрет «ниппель лежит на незакреплённой муфте» и «ниппель лежит на муфте вообще»
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local cq, nq
for q, p in ipairs(lvl.pieces) do if p.tag == "cpl" then cq = q elseif p.tag == "nip" then nq = q end end
local tests = {
  { "ниппель не лежит на незакреплённой муфте", function(l, st, ns)
      local n, c = ns.pos[nq], ns.pos[cq]
      if n == 0 or c == 0 or ns.fixed[cq] then return true end
      return l.nb[n][3] ~= c end },
  { "ниппель не лежит на муфте (любой)", function(l, st, ns)
      local n, c = ns.pos[nq], ns.pos[cq]
      if n == 0 or c == 0 or ns.fixed[nq] then return true end
      return l.nb[n][3] ~= c end },
  { "муфта не лежит на ниппеле", function(l, st, ns)
      local n, c = ns.pos[nq], ns.pos[cq]
      if n == 0 or c == 0 or ns.fixed[cq] then return true end
      return l.nb[c][3] ~= n end },
}
for _, t in ipairs(tests) do
  local G = SV.explore(lvl, 3000000, t[2])
  print(string.format("%s: %s", t[1], (G and G.firstWin) and ("РЕШАЕМ, " .. G.depth[G.firstWin]) or "нерешаем"))
  if G then SV.freeGraph(G) end
end
