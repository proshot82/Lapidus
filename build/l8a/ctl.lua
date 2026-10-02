-- build/l8a/ctl.lua файл.lua — контроли (def.controls): решаемость и длина при фильтре. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
for _, c in ipairs(def.controls or {}) do
  local G = SV.explore(lvl, 3000000, c.filter)
  print(string.format("контроль «%s»: %s (состояний %d)", c.name, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ", G.n))
  SV.freeGraph(G)
end
