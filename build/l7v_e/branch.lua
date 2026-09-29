-- build/l7v_e/branch.lua файл.lua — по шагам кратчайшего пути: сколько ходов живые / скрытые (глубина) / видимые. Ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local path = m.path
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
      if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; q[#q+1] = v end end end
  return maxd, #q
end
for k = 1, #path - 1 do
  local s = path[k]
  local L, Hd, Vs, W = 0, {}, 0, 0
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do local j = G.edges.p[e]
    if G.flag[j] == 2 then W = W + 1 elseif good[j] == 1 then L = L + 1 elseif VL.newbie[j] then Vs = Vs + 1 else local d, sz = depthFrom(j); Hd[#Hd+1] = d .. "/" .. sz end end
  print(string.format("шаг %2d: живых %d, скрытых [%s], видимых %d, смыло %d", k-1, L, table.concat(Hd, " "), Vs, W))
end
