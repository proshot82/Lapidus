-- Разбор ловушек: связные компоненты скрытых тупиков (не смыт ни Лапидус, ни деталь), их размер,
-- на каком ходу пути в них можно войти и сколько ходов можно бродить до «очевидного» конца.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local id = tonumber(arg[1])
local def = dofile(string.format("levels/%02d.lua", id))
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return false
end
local hidden = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] ~= 1 then
    local st = R.decode(lvl, G.keys[i])
    if not lost(st) then hidden[i] = true end
  end
end
-- неориентированные компоненты среди скрытых тупиков
local comp, sizes = {}, {}
local nc = 0
local adj = {}
for i = 1, G.n do
  for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
    local j = G.edges.p[e]
    if hidden[i] and hidden[j] then
      adj[i] = adj[i] or {}; adj[j] = adj[j] or {}
      adj[i][#adj[i] + 1] = j; adj[j][#adj[j] + 1] = i
    end
  end
end
for i in pairs(hidden) do
  if not comp[i] then
    nc = nc + 1
    local q, h = { i }, 1
    comp[i] = nc
    while h <= #q do
      local u = q[h]; h = h + 1
      for _, v in ipairs(adj[u] or {}) do if not comp[v] then comp[v] = nc; q[#q + 1] = v end end
    end
    sizes[nc] = #q
  end
end
-- путь и входы в компоненты с пути
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local entries = {}
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if hidden[j] then
      local c = comp[j]
      entries[c] = entries[c] or {}
      entries[c][#entries[c] + 1] = k - 1
    end
  end
end
-- глубина: самый длинный путь без повторов оценим как BFS-эксцентриситет от точки входа внутри компоненты (направленно)
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
local list = {}
for c, sz in pairs(sizes) do list[#list + 1] = { c = c, sz = sz } end
table.sort(list, function(a, b) return a.sz > b.sz end)
local nh = 0
for _ in pairs(hidden) do nh = nh + 1 end
print(string.format("кв. %d: ходов %d, скрытых тупиков %d в %d компонентах", id, #path - 1, nh, nc))
for k = 1, math.min(6, #list) do
  local c = list[k].c
  local ent = entries[c]
  local deep = 0
  if ent then
    -- глубина от первого входа
    local s = path[ent[1] + 1]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do local j = G.edges.p[e]; if hidden[j] and comp[j] == c then deep = math.max(deep, depthFrom(j)) end end
  end
  print(string.format("  компонента: %d состояний; вход с пути после ходов %s; глубина блуждания ≈ %d ходов",
    list[k].sz, ent and table.concat(ent, ",") or "— (не с кратчайшего пути)", deep))
end
SV.freeGraph(G); require("ffi").C.free(good)
