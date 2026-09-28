-- vischeck.lua файл.lua — помечает ли visibleLoss живые состояния (должно быть 0) и сколько мёртвых по видам.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local bad, vis, hid = 0, 0, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local l = def.visibleLoss(lvl, st)
    if good[i] == 1 and l then bad = bad + 1 end
    if good[i] ~= 1 then if l then vis = vis + 1 else hid = hid + 1 end end
  end
end
print(string.format("живых, помеченных видимыми: %d; мёртвых видимых %d, скрытых %d", bad, vis, hid))
SV.freeGraph(G); require("ffi").C.free(good)
