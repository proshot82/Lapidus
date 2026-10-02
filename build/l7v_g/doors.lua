-- build/l7v_g/doors.lua файл.lua — «двери»: число рёбер живое→скрытое / живое→видимое / живое→смыло (мерка новичка и знатока).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local c = { live = 0, hidN = 0, hidE = 0, vis = 0, wash = 0 }
for i = 1, G.n do if flag[i] == 0 and good[i] == 1 then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if flag[j] == 2 then c.wash = c.wash + 1 elseif good[j] == 1 then c.live = c.live + 1
    elseif VL.newbie[j] then c.vis = c.vis + 1 else c.hidN = c.hidN + 1; if not VL.expert[j] then c.hidE = c.hidE + 1 end end
  end end end
print(string.format("рёбра из живых: в живые %d | в скрытые (новичок) %d, из них скрытые и знатоку %d | в видимые %d | смыло %d", c.live, c.hidN, c.hidE, c.vis, c.wash))
SV.freeGraph(G); require("ffi").C.free(good)
