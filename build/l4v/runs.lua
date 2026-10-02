-- build/l4v/runs.lua — самая длинная серия одинаковых ходов на кратчайшем пути и число «смен направления» (только числа).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l4d/k29.lua")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local mv, x = {}, G.firstWin
while x ~= 1 do table.insert(mv, 1, G.pmove[x]); x = G.parent[x] end
local run, best, changes = 1, 1, 0
for i = 2, #mv do if mv[i] == mv[i-1] then run = run + 1; if run > best then best = run end else run = 1; changes = changes + 1 end end
print(string.format("ходов %d, самая длинная серия одинаковых ходов %d, смен хода %d", #mv, best, changes))
