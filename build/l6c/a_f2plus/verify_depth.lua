-- verify_depth.lua файл.lua — глубина скрытых веток: для каждой клетки кратчайшего пути расстояние до ближайшего входа
-- в скрытую ветку (по живым состояниям) и глубина этой ветки. Решения не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local hidden = {}
for i = 1, G.n do if G.flag[i] == 0 and good[i] ~= 1 then
  local s = R.decode(lvl, G.keys[i]); local l = false
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then l = true end end
  if not l and def.visibleLoss then l = def.visibleLoss(lvl, s) end
  if not l then hidden[i] = true end
end end
local function depthFrom(j)
  local d, q, h, m = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
      if hidden[v] and not d[v] then d[v] = d[u] + 1; if d[v] > m then m = d[v] end; q[#q+1] = v end end end
  return m
end
local best = 0
for i = 1, G.n do if good[i] == 1 then
  for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
    if hidden[j] then local d = depthFrom(j); if d > best then best = d end end end
end end
print("макс. глубина скрытой ветки из любого живого состояния: " .. best)
