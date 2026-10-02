-- sol.lua файл.lua — ходы кратчайшего решения в формате pl.lua (ТОЛЬКО вывод инструмента; в файлы не переносить).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, G.pmove[x]); x = G.parent[x] end
local A = { "^", ">", "v", "<" }
local t = {}
for _, m in ipairs(path) do local mm = R.MOVES[m]; t[#t + 1] = (mm.which == "head" and "H" or "F") .. A[mm.dir] end
print(table.concat(t, " "))
SV.freeGraph(G)
