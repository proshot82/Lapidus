-- verify_hint1.lua файл.lua [уровень_vis] — достижима ли ошибка подсказки №1 («ниппель в колонку») и куда она ведёт.
-- Печатает: сколько таких состояний, живых среди них, видимых (по vis_e и по verify_vis 1/2), минимальное расстояние
-- от кратчайшего пути (в ходах) и глубину скрытой ветки из ближайшего такого состояния. Кадров не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local VV = dofile("build/l6c/e_orientation/verify_vis.lua")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local nq, cq
for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nq = q elseif p.tag == "cpl" then cq = q end end
local vis = { def.visibleLoss, VV(1), VV(2) }
local function lostBy(f, st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return f(lvl, st)
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
-- BFS от всех состояний пути
local dist, q, h = {}, {}, 1
for k, s in ipairs(path) do dist[s] = 0; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] ~= 2 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; q[#q + 1] = v end end
  end
end
local cnt, liveN, visN, best, bestD = 0, 0, { 0, 0, 0 }, nil, 1e9
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    if st.pos[nq] ~= 0 and st.fixed[nq] and not st.fixed[cq] and st.pos[cq] ~= 0 then
      cnt = cnt + 1
      if good[i] == 1 then liveN = liveN + 1 end
      for k = 1, 3 do if lostBy(vis[k], st) then visN[k] = visN[k] + 1 end end
      if dist[i] and dist[i] < bestD then bestD = dist[i]; best = i end
    end
  end
end
print(string.format("ниппель в колонке, муфта свободна: состояний %d, живых %d, видимых vis_e/v1/v2: %d/%d/%d",
  cnt, liveN, visN[1], visN[2], visN[3]))
print("минимальное расстояние от кратчайшего пути, ходов: " .. tostring(bestD) .. ", глубина от старта: " .. tostring(best and G.depth[best]))
-- глубина скрытой ветки (по vis_e и v2) из ближайшего такого состояния
for k = 1, 3, 2 do
  local d, qq, hh, maxd = { [best] = 0 }, { best }, 1, 0
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if d[v] == nil and G.flag[v] ~= 2 and good[v] ~= 1 and not lostBy(vis[k], R.decode(lvl, G.keys[v])) then
        d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq + 1] = v end
    end
  end
  print(string.format("скрытая ветка из него (vis %s): %d состояний, глубина %d", k == 1 and "vis_e" or "v2", #qq, maxd))
end
SV.freeGraph(G); require("ffi").C.free(good)
