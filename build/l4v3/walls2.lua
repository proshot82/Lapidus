-- build/l4v3/walls2.lua — замуровка стартовой клетки муфты t16 (5,3): муфту ставим туда, куда она падает сама
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local R = require("core.rules")
local L = dofile("build/l4v3/lib.lua")
local d = dofile("build/l4e/t16.lua")
local d2 = SV.deepcopy(d)
for _, o in ipairs(d2.objects) do if o.tag == "cpl" then o.at = { 5, 5 } end end
local lvl = R.compile(d2); local st = R.newState(lvl)
print("муфта в (5,5) с начала: " .. (R.key(st) and "ок"))
local A = L.load(d2); print(string.format("  ходов %d сост %d", A.opt, A.G.n)); L.free(A)
local d3 = SV.deepcopy(d2)
d3.grid[3] = d3.grid[3]:sub(1, 4) .. "#" .. d3.grid[3]:sub(6)
local A3 = L.load(d3); if A3.unsolvable then print("  + стена (5,3): НЕРЕШАЕМ") else print(string.format("  + стена (5,3): ходов %d", A3.opt)) end
