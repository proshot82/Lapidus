-- build/l6c/a_f2plus/vischeck.lua файл.lua — честность visibleLoss: сколько ЖИВЫХ состояний помечено как проигрыш (должно быть 0)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local bad, vis = 0, 0
for i = 1, G.n do
  if G.flag[i] == 0 then
    local st = R.decode(lvl, G.keys[i])
    if def.visibleLoss and def.visibleLoss(lvl, st) then vis = vis + 1; if good[i] == 1 then bad = bad + 1 end end
  end
end
print(string.format("visibleLoss: помечено %d, из них ЖИВЫХ %d%s", vis, bad, bad > 0 and "  <-- НЕЧЕСТНО" or ""))
SV.freeGraph(G); require("ffi").C.free(good)
