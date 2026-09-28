-- walks.lua файл.lua — шаблон кратчайшего пути: * ход с событием деталей, . прогулка (без самих ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
local s = {}
for i = 1, #path - 1 do s[#s+1] = (objs(path[i]) ~= objs(path[i+1])) and "*" or "." end
print(table.concat(s))
SV.freeGraph(G)
