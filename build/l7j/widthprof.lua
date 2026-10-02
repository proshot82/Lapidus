-- build/l7j/widthprof.lua файл.lua — ширина коридора кратчайших по шагам (сколько разных состояний на каждом шаге)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local opt = G.depth[G.firstWin]
local ES, E = G.eStart.p, G.edges.p
local on = {}
for i = G.n, 1, -1 do
  if G.flag[i] == 1 and G.depth[i] == opt then on[i] = true
  elseif G.flag[i] == 0 and G.depth[i] < opt then
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true break end end
  end
end
local wd = {}
for i = 1, G.n do if on[i] then wd[G.depth[i]] = (wd[G.depth[i]] or 0) + 1 end end
local t = {}
for d = 0, opt do t[#t + 1] = tostring(wd[d] or 0) end
print("ширина по шагам: " .. table.concat(t, " "))
