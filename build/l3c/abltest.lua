-- build/l3c/abltest.lua файл.lua — прогон фильтров абляций из abl3.lua: решаем ли уровень и за сколько
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local A = dofile("build/l3c/abl3.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
for _, name in ipairs({ "noKick", "noStack", "noBridge", "noLift", "noLeft", "noCorner", "noHeadRest", "noPocketFeet" }) do
  local G = SV.explore(lvl, 3000000, A[name])
  print(string.format("%-9s %s (состояний %d)", name, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ", G.n))
  SV.freeGraph(G)
end
