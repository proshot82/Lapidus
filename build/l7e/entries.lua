-- build/l7e/entries.lua файл.lua — входы живое → скрытый тупик: по смене конфигурации деталей, с глубиной хвоста
-- и минимальной BFS-глубиной живого состояния. Порядка ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
      if m.hidden[v] and d[v] == nil then d[v] = d[u]+1; if d[v] > maxd then maxd = d[v] end; q[#q+1] = v end end end
  return maxd
end
local agg = {}
for i = 1, G.n do if good[i] == 1 then
  for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
    if m.hidden[j] then
      local k = cfg(VL.states[i]) .. "  →  " .. cfg(VL.states[j])
      local a = agg[k] or { n = 0, minD = 999, tail = 0 }; agg[k] = a
      a.n = a.n + 1
      if G.depth[i] < a.minD then a.minD = G.depth[i] end
      local t = depthFrom(j); if t > a.tail then a.tail = t end
    end end end end
local l = {}
for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return x[2].n > y[2].n end)
print("вход (конфигурация до → после)                                   переходов  от глубины  хвост")
for _, e in ipairs(l) do print(string.format("%-66s %5d %6d %6d", e[1], e[2].n, e[2].minD, e[2].tail)) end
