-- vischeck.lua файл.lua — проверка честности visibleLoss: сколько ЖИВЫХ состояний помечено видимым проигрышем (должно быть 0).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local bad, vis = 0, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    if def.visibleLoss(lvl, st) then vis = vis + 1; if good[i] == 1 then bad = bad + 1 end end
  end
end
print(string.format("помечено видимыми %d, из них живых %d", vis, bad))
SV.freeGraph(G); require("ffi").C.free(good)
