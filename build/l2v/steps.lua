-- build/l2v/steps.lua — по шагам кратчайшего пути: сколько ходов ведёт в живое / в мёртвое (не смыт) / в смыв. Только числа.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1]); local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000); local good = SV.goodSet(G)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local out, withDead = {}, 0
for k = 1, #path - 1 do local s = path[k]; local l, d, w = 0, 0, 0
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do local j = G.edges.p[e]
    if G.flag[j] == 2 then w = w + 1 elseif good[j] == 1 then l = l + 1 else d = d + 1 end end
  if d > 0 then withDead = withDead + 1 end
  out[#out+1] = l .. "/" .. d .. "/" .. w end
print("живые/мёртвые/смыв по шагам: " .. table.concat(out, " "))
print("шагов пути с ходом в мёртвое (не смыт): " .. withDead .. " из " .. (#path - 1))
