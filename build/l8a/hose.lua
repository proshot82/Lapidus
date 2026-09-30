-- build/l8a/hose.lua файл… — решаем ли кандидат без брандспойта (абляция F.noHose) и без Лапидуса-в-струе. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local F = dofile("build/l8a/filt.lua")
for _, f in ipairs(arg) do
  local def = dofile(f)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000, F.noHose)
  print(string.format("%-8s без брандспойта: %s (состояний %d)", f:match("([^/]+)%.lua$"),
    G.firstWin and ("РЕШАЕМ за " .. G.depth[G.firstWin]) or "нерешаем", G.n))
  SV.freeGraph(G)
end
