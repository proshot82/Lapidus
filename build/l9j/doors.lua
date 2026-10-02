-- build/l9j/doors.lua файл.lua — двери с кратчайшего пути: шаг, глубина скрытой области, конфигурация деталей после ошибки
-- (для автора; печатает только в вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local hidden = {}
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then hidden[i] = true end end
local function cfg(i)
  local s = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "(-)" else local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  local b = s.body; local hx, hy = R.xy(lvl, b[#b]); local fx, fy = R.xy(lvl, b[1])
  return table.concat(t, " ") .. string.format(" H(%d,%d) f(%d,%d) L%d", hx, hy, fx, fy, #b)
end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
print("ходов", #path - 1)
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if hidden[j] then print(string.format("шаг %d: глубина %d  %s  →  %s", k - 1, depthFrom(j), cfg(s), cfg(j))) end
  end
end
SV.freeGraph(G)
