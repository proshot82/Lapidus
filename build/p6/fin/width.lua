-- ширина коридора кратчайших решений по шагам (только вывод инструмента)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
-- расстояние до победы обратным BFS
local n = G.n
local radj = {}
for i = 1, n do for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]; radj[j] = radj[j] or {}; table.insert(radj[j], i) end end
local dist = {}
local q, h = {}, 1
for i = 1, n do if G.flag[i] == 1 then dist[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(radj[j] or {}) do if not dist[i] then dist[i] = dist[j] + 1; q[#q+1] = i end end end
local opt = dist[1]
local layer = { [0] = { [1] = true } }
for d = 0, opt - 1 do
  layer[d+1] = {}
  for i in pairs(layer[d]) do
    for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]; if dist[j] == opt - d - 1 and G.depth[j] == d + 1 then layer[d+1][j] = true end end
  end
end
local out = {}
for d = 0, opt do local c = 0; for _ in pairs(layer[d]) do c = c + 1 end; out[#out+1] = c end
print("состояний на шаг кратчайших: " .. table.concat(out, " "))
