-- verify2_claims.lua файл.lua — ошибка из подсказки №1 (тройник поехал лифтом раньше заглушки/переходника):
-- достижимость, живые/видимые/скрытые по разметкам verify2_vis.lua, ближайшее к кратчайшему пути скрытое
-- состояние ошибки и скрытая ветка из него; «конкретные состояния» — по одному на класс (конфигурация деталей
-- без Лапидуса, глубина от старта). Решений и кадров не печатает.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l7c/b_lift_cargo/verify2_lib.lua")
local V = dofile("build/l7c/b_lift_cargo/verify2_vis.lua")
local VA = dofile("build/l7c/b_lift_cargo/vis.lua")
local R = L.R
local def = dofile(arg[1])
local lvl, G, good = L.graph(def)
local k = L.keys(lvl)
local sx, sy = k.sx, k.sy
local S = {}
for i = 1, G.n do if G.flag[i] ~= 2 then S[i] = R.decode(lvl, G.keys[i]) end end
local modes = { "mine", "wide(автор)", "honest-N", "honest" }
local vis = {}
for _, m in ipairs(modes) do
  local f = (m == "wide(автор)") and VA.make("wide") or V.make(def, m)
  local t = {}
  for i = 1, G.n do if G.flag[i] == 0 and good[i] ~= 1 then t[i] = L.washed(lvl, S[i]) or f(lvl, S[i]) end end
  vis[m] = t
end
local path = L.path(G)
local onPath = {}
for idx, s in ipairs(path) do onPath[s] = idx - 1 end
-- расстояние от кратчайшего пути (в ходах, только вперёд по графу)
local dist, q, h = {}, {}, 1
for _, s in ipairs(path) do dist[s] = 0; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] == 0 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; q[#q + 1] = v end end
  end
end
-- от какой точки пути ближе всего (шаг пути)
local fromStep = {}
do
  local qq, hh = {}, 1
  for _, s in ipairs(path) do fromStep[s] = onPath[s]; qq[#qq + 1] = s end
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    if G.flag[u] == 0 then
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if fromStep[v] == nil then fromStep[v] = fromStep[u]; qq[#qq + 1] = v end end
    end
  end
end
local function hiddenBranch(from, visM)
  local d, qq, hh, maxd = { [from] = 0 }, { from }, 1, 0
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if d[v] == nil and G.flag[v] == 0 and good[v] ~= 1 and not visM[v] then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq + 1] = v end
    end
  end
  return #qq, maxd
end
local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local function risen(c) if not inCol(c) then return false end local _, y = R.xy(lvl, c); return y < sy - lvl.R end
local traps = {
  { "тройник поднят лифтом раньше заглушки (ошибка подсказки №1, ложный план)", function(st) return risen(st.pos[k.tee]) and not inCol(st.pos[k.plug]) end },
  { "тройник в столбе раньше переходника (вторая половина подсказки)", function(st) return inCol(st.pos[k.tee]) and not st.fixed[k.tee] and not inCol(st.pos[k.adp]) end },
  { "ложный план доведён: тройник прикручен у мойки раньше заглушки", function(st) return st.fixed[k.tee] and not inCol(st.pos[k.plug]) end },
  { "тройник у мойки с заглушкой, переходник не в столбе", function(st) return st.fixed[k.tee] and inCol(st.pos[k.plug]) and not inCol(st.pos[k.adp]) end },
  { "ниппель в основании раньше тройника", function(st) return st.fixed[k.nip] and not inCol(st.pos[k.tee]) end },
}
for _, t in ipairs(traps) do
  print(t[1] .. ":")
  local n, live = 0, 0
  local cnt = {}
  local best = {}
  for i = 1, G.n do
    local st = S[i]
    if st and G.flag[i] == 0 and t[2](st) then
      n = n + 1
      if good[i] == 1 then live = live + 1 else
        for _, m in ipairs(modes) do
          if vis[m][i] then cnt[m] = (cnt[m] or 0) + 1
          elseif dist[i] and (not best[m] or dist[i] < dist[best[m]] or (dist[i] == dist[best[m]] and G.depth[i] < G.depth[best[m]])) then best[m] = i end
        end
      end
    end
  end
  print(string.format("   состояний %d, живых %d", n, live))
  for _, m in ipairs(modes) do
    local line = string.format("   %-11s видимых %d, скрытых %d", m, cnt[m] or 0, n - live - (cnt[m] or 0))
    local b = best[m]
    if b then
      local sz, dp = hiddenBranch(b, vis[m])
      line = line .. string.format("; ближайшее скрытое — в %d ход(а) от пути (у шага %d), глубина от старта %d, [%s]; скрытая ветка из него: %d сост., глубина %d",
        dist[b], fromStep[b] or -1, G.depth[b], L.cfg(lvl, S[b]), sz, dp)
    end
    print(line)
  end
end
L.SV.freeGraph(G); require("ffi").C.free(good)
