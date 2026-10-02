-- width.lua файл.lua — ширина коридора кратчайших решений по шагам (без ходов и кадров).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local n = G.n
local E, ES = G.edges.p, G.eStart.p
local rev = {}
for i = 1, n do
  for e = ES[i - 1], ES[i] - 1 do
    local j = E[e]
    local t = rev[j]; if not t then t = {}; rev[j] = t end
    t[#t + 1] = i
  end
end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q + 1] = i end end
while h <= #q do
  local u = q[h]; h = h + 1
  for _, p in ipairs(rev[u] or {}) do if dw[p] == nil and G.flag[p] ~= 2 then dw[p] = dw[u] + 1; q[#q + 1] = p end end
end
local opt = G.depth[G.firstWin]
local w = {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then w[G.depth[i]] = (w[G.depth[i]] or 0) + 1 end end
local t = {}
for d = 0, opt do t[#t + 1] = tostring(w[d] or 0) end
print("ширина по шагам: " .. table.concat(t, " "))
SV.freeGraph(G)
