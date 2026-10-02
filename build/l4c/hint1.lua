-- build/l4c/hint1.lua файл.lua [main|wide] — ошибка подсказки №1 на конкретных состояниях (без кадров).
-- Считает по конфигурациям деталей: (а) собранная заранее пара; (б) «ниппель раньше муфты» — ниппель упал в коридор
-- (или в шахту), когда муфта ещё не в шахте и не впереди него. Для каждой — живых / скрытых / видимых и глубину скрытой
-- области от ближайшего к кратчайшему пути такого состояния.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local mode = arg[2] or "main"
local vis = def.visibleLoss
if mode == "wide" then vis = dofile("build/l4c/vis_wide.lua") end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local qc, qn, S
for q, p in ipairs(lvl.pieces) do
  if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end
  if p.source then S = p.start end
end
local T = lvl.nb[lvl.nb[S][1]][1]
local W = lvl.W
local rowT = math.floor((T - 1) / W) + 1
local st = {}
local function S_(i) st[i] = st[i] or R.decode(lvl, G.keys[i]); return st[i] end
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return vis(lvl, s)
end
local hidden = {}
for i = 1, G.n do if G.flag[i] == 0 and good[i] ~= 1 and not lost(S_(i)) then hidden[i] = true end end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local dist, q, h = {}, {}, 1
for _, s in ipairs(path) do dist[s] = 0; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] ~= 2 then for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; q[#q + 1] = v end end end
end
local function depthFrom(j)
  local d, qq, hh, maxd = { [j] = 0 }, { j }, 1, 0
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq + 1] = v end
    end
  end
  return maxd, #qq
end
local kinds = {
  { "собранная заранее пара", function(s) return s.pos[qc] ~= 0 and s.pos[qn] ~= 0 and not s.fixed[qc] and s.asm[qc] == s.asm[qn] end },
  { "ниппель раньше муфты", function(s)
      if s.pos[qc] == 0 or s.pos[qn] == 0 or s.fixed[qc] or s.asm[qc] == s.asm[qn] then return false end
      local n, c = s.pos[qn], s.pos[qc]
      if s.fixed[qn] then return true end
      local ny, cy = math.floor((n - 1) / W) + 1, math.floor((c - 1) / W) + 1
      local nx, cx, tx = (n - 1) % W + 1, (c - 1) % W + 1, (T - 1) % W + 1
      return ny == rowT and cy == rowT and math.abs(tx - nx) < math.abs(tx - cx) and (tx - nx) * (tx - cx) > 0 end },
}
for _, k in ipairs(kinds) do
  local n, live, hid, visn, best, bestD = 0, 0, 0, 0, nil, 1e9
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      local s = S_(i)
      if k[2](s) then
        n = n + 1
        if good[i] == 1 then live = live + 1 elseif hidden[i] then hid = hid + 1 else visn = visn + 1 end
        if hidden[i] and dist[i] and dist[i] < bestD then bestD = dist[i]; best = i end
      end
    end
  end
  local dd, nn = 0, 0
  if best then dd, nn = depthFrom(best) end
  print(string.format("[%s] %s: состояний %d — живых %d, скрытых %d, видимых %d; ближайшее скрытое в %s ходах от пути, скрытая область из него: глубина %d, %d сост.",
    mode, k[1], n, live, hid, visn, best and tostring(bestD) or "—", dd, nn))
end
SV.freeGraph(G); require("ffi").C.free(good)
