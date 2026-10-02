-- build/l3d/doors_all.lua файл [карман] — двери со ВСЕХ кратчайших путей: для каждого шага (номер хода от старта)
-- — в какие классы скрытых (по положению мыла) ведут ходы из состояний, лежащих на каком-нибудь кратчайшем пути.
-- Печатает только номера шагов и классы; ходов и кадров нет.
package.path = "./?.lua;" .. package.path
local V = require("tools.vislib")
V.POCKET = tonumber(arg[2] or 4)
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1])
local G = ctx.G
local opt = G.depth[G.firstWin]
local rev = {}
for i = 1, G.n do if G.flag[i] ~= 2 then for _, j in ipairs(L.edges(ctx, i)) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end end
local dist = { [G.firstWin] = 0 }
local q, h = { G.firstWin }, 1
while h <= #q do local u = q[h]; h = h + 1; for _, p in ipairs(rev[u] or {}) do if dist[p] == nil then dist[p] = dist[u] + 1; q[#q + 1] = p end end end
local by = {}
local nOn = 0
for i = 1, G.n do
  if G.flag[i] == 0 and dist[i] and G.depth[i] + dist[i] == opt then
    nOn = nOn + 1
    for _, j in ipairs(L.edges(ctx, i)) do
      if L.status(ctx, j) == "hid" then
        local k = L.cfg(ctx, ctx.sts[j])
        by[k] = by[k] or {}
        by[k][G.depth[i]] = true
      end
    end
  end
end
print(string.format("кратчайших ходов %d, состояний на кратчайших путях %d, карман %d", opt, nOn, V.POCKET))
for k, steps in pairs(by) do
  local t = {}
  for s in pairs(steps) do t[#t + 1] = s end
  table.sort(t)
  print(string.format("  %-30s шаги: %s", k, table.concat(t, " ")))
end
L.free(ctx)
