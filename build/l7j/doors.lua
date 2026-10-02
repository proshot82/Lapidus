-- build/l7j/doors.lua файл.lua — двери с кратчайшего пути: шаг, ход, что меняется в деталях, глубина скрытой ветки.
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
local function cfg(i)
  local st = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = p.tag .. "смыт" else local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if m.hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd, #q
end
for k = 1, #m.path - 1 do
  local s = m.path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if m.hidden[j] then
      local d, sz = depthFrom(j)
      print(string.format("шаг %d: %s  [%s] -> [%s]  глубина %d, область %d", k - 1, R.moveName(G.pmove[j]), cfg(s), cfg(j), d, sz))
    end
  end
end
