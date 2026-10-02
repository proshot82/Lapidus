-- build/l7v_g/ablsize.lua файл.lua — размер пространства под каждой авторской абляцией-фильтром (не слишком ли широк фильтр).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G0 = SV.explore(lvl, 3000000); print("без фильтра: состояний " .. G0.n); SV.freeGraph(G0)
for _, a in ipairs(def.ablations) do if a.filter then
  local G = SV.explore(lvl, 3000000, a.filter)
  print(string.format("%-45s состояний %6d  %s", a.name, G.n, G.firstWin and ("РЕШАЕМ за " .. G.depth[G.firstWin]) or "нерешаем"))
  SV.freeGraph(G) end end
