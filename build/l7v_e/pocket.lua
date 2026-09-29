-- build/l7v_e/pocket.lua файл.lua N — метрики при размере кармана линейки N (в линейке 3)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
for N = 3, 7 do
  V.POCKET = N
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  print(string.format("карман %d: скрытых %d = %.1f %%, обезьяна %.3f, глубина %d [%s]", N, m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
end
