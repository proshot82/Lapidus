-- build/l3v3/jelly2.lua [файл] [k] — различные последовательности событий с мылом (конфигурации без повторов подряд)
-- среди всех выигрышных путей длины ≤ opt+k (по умолчанию k = 4); и среди кратчайших.
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
local K = tonumber(arg[2] or 4)
local ctx = L.load(path, 4)
local G = ctx.G
local dist = L.distToWin(ctx)
local opt = G.depth[G.firstWin]
local function cfg(i) return L.cfg(ctx, ctx.sts[i], true) end
local seqs = {} -- строка последовательности → { минимальная длина, число путей }
local acc = { cfg(1) }
local function dfs(u, depth, budget)
  if G.flag[u] == 1 then
    local s = table.concat(acc, " → ")
    local e = seqs[s] or { min = 1e9, n = 0 }
    seqs[s] = e
    e.n = e.n + 1; if depth < e.min then e.min = depth end
    return
  end
  for _, v in ipairs(L.edges(ctx, u)) do
    if G.flag[v] ~= 2 and dist[v] and dist[v] <= budget - 1 then
      local c = cfg(v)
      local pushed = false
      if c ~= acc[#acc] then acc[#acc + 1] = c; pushed = true end
      dfs(v, depth + 1, budget - 1)
      if pushed then acc[#acc] = nil end
    end
  end
end
dfs(1, 0, opt + K)
local l = {}
for s, e in pairs(seqs) do l[#l + 1] = { s, e } end
table.sort(l, function(a, b) return a[2].min < b[2].min or (a[2].min == b[2].min and a[2].n > b[2].n) end)
print(string.format("путей длины ≤ %d: различных последовательностей событий %d", opt + K, #l))
for _, e in ipairs(l) do print(string.format("   мин. %d ходов, путей %d: %s", e[2].min, e[2].n, e[1])) end
L.free(ctx)
