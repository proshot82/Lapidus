-- build/l3v3/jelly.lua [файл] — «реальные решения игрока»: различные последовательности событий с мылом среди
-- всех выигрышных путей (граф конфигураций по живым состояниям, проверка реализуемости), число путей длины ≤ opt+k.
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
local ctx = L.load(path, 4)
local G = ctx.G
local function cfg(i) return L.cfg(ctx, ctx.sts[i], true) end
-- граф конфигураций по живым рёбрам
local nodes, adj = {}, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and (ctx.good[i] == 1) then
    local a = cfg(i); nodes[a] = (nodes[a] or 0) + 1
    for _, j in ipairs(L.edges(ctx, i)) do
      if G.flag[j] ~= 2 and ctx.good[j] == 1 then
        local b = cfg(j)
        if a ~= b then adj[a] = adj[a] or {}; adj[a][b] = (adj[a][b] or 0) + 1 end
      end
    end
  end
end
local start, winc = cfg(1), cfg(G.firstWin)
print("живые конфигурации мыла (число состояний):")
for k, v in pairs(nodes) do
  local out = {}
  for b, c in pairs(adj[k] or {}) do out[#out + 1] = b .. "(" .. c .. ")" end
  print(string.format("   %-22s %4d  →  %s", k, v, table.concat(out, "  ")))
end
-- простые пути в графе конфигураций
local seqs = {}
local function dfs(u, acc, vis)
  if u == winc then seqs[#seqs + 1] = table.concat(acc, " → "); return end
  for v in pairs(adj[u] or {}) do if not vis[v] then vis[v] = true; acc[#acc + 1] = v; dfs(v, acc, vis); acc[#acc] = nil; vis[v] = nil end end
end
dfs(start, { start }, { [start] = true })
-- реализуемость: BFS по состояниям с автоматом последовательности
local function realizable(seq)
  local list = {}
  for s in seq:gmatch("[^→]+") do list[#list + 1] = s:match("^%s*(.-)%s*$") end
  local seen = { [1 .. ":1"] = true }
  local q, h = { { 1, 1 } }, 1
  local best
  while h <= #q do
    local u, k = q[h][1], q[h][2]; h = h + 1
    if G.flag[u] == 1 and k == #list then best = G.depth[u]; return true, best end
    for _, v in ipairs(L.edges(ctx, u)) do
      if G.flag[v] ~= 2 and ctx.good[v] == 1 then
        local c = cfg(v)
        local k2
        if c == list[k] then k2 = k elseif k < #list and c == list[k + 1] then k2 = k + 1 end
        if k2 and not seen[v .. ":" .. k2] then seen[v .. ":" .. k2] = true; q[#q + 1] = { v, k2 } end
      end
    end
  end
  return false
end
print(string.format("\nпростых путей в графе конфигураций: %d; реализуемых (есть путь состояний с такой последовательностью событий):", #seqs))
local nreal = 0
for _, s in ipairs(seqs) do
  local ok, d = realizable(s)
  if ok then nreal = nreal + 1; print(string.format("   [%d ходов мин.] %s", d, s)) end
end
print("реализуемых последовательностей событий: " .. nreal)
-- число путей (с блужданием) длины ≤ opt+k до победы
local opt = G.depth[G.firstWin]
local cnt = { [1] = 1 }
local wins = {}
for d = 1, opt + 6 do
  local nc = {}
  for i, c in pairs(cnt) do
    if G.flag[i] == 0 then
      for _, j in ipairs(L.edges(ctx, i)) do
        if G.flag[j] ~= 2 then nc[j] = (nc[j] or 0) + c end
      end
    end
  end
  cnt = nc
  local w = 0
  for i, c in pairs(cnt) do if G.flag[i] == 1 then w = w + c end end
  if d >= opt then wins[#wins + 1] = string.format("%d:%d", d, w) end
end
print("выигрышных путей по длине (длина:число): " .. table.concat(wins, " "))
L.free(ctx)
