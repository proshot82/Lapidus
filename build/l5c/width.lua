-- build/l5c/width.lua файл.lua — ширина коридора кратчайших решений по шагам (число разных состояний на каждой
-- глубине, лежащих на каком-нибудь кратчайшем решении). Кадров и ходов не печатает.
package.path = "./?.lua;" .. package.path
local ST = require("solver.strict")
local def = dofile(arg[1])
local G = ST.graph(def, 3000000)
local cnt = { [1] = 1 }
for i = 1, G.n do
  local c = cnt[i]
  if c and not G.win[i] and not G.dead[i] then
    for _, j in ipairs(G.succ[i]) do if G.dist[j] == G.dist[i] + 1 then cnt[j] = (cnt[j] or 0) + c end end
  end
end
local on = {}
for i = 1, G.n do if G.win[i] and G.dist[i] == G.opt then on[i] = true end end
for i = G.n, 1, -1 do
  if not on[i] and not G.win[i] and not G.dead[i] and G.dist[i] < G.opt then
    for _, j in ipairs(G.succ[i]) do if on[j] and G.dist[j] == G.dist[i] + 1 then on[i] = true; break end end
  end
end
local w = {}
for i = 1, G.n do if on[i] then w[G.dist[i]] = (w[G.dist[i]] or 0) + 1 end end
local t = {}
for d = 0, G.opt do t[#t + 1] = tostring(w[d] or 0) end
print("ширина по шагам: " .. table.concat(t, " "))
