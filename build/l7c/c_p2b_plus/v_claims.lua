-- v_claims.lua файл.lua — ошибка из подсказки №1 на конкретных состояниях (кв. 7, кандидат c7): для каждого класса
-- ошибки — сколько состояний (живых / скрытых / видимых) по общей линейке tools/vislib.lua (новичок, знаток) и fvis.lua,
-- как близко к кратчайшему пути, ближайшее скрытое состояние (конфигурация деталей без Лапидуса) и скрытая ветка
-- из него. Решений, ходов и кадров не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/c_p2b_plus/fvis.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local E, ES = G.edges.p, G.eStart.p
local P = lvl.pieces
local k = {}
for q, p in ipairs(P) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end end
local sx, sy = R.xy(lvl, P[k.src].start)
local qy = sy - 1 -- ряд очереди (первая клетка струи)
local nx0 = R.xy(lvl, P[k.nip].start)
local px0 = R.xy(lvl, P[k.plug].start)
local S = {}
for i = 1, G.n do if G.flag[i] ~= 2 then S[i] = R.decode(lvl, G.keys[i]) end end
local function washed(st) for q, p in ipairs(P) do if p.movable and st.pos[q] == 0 then return true end end return false end
-- мерки: общая линейка tools/vislib.lua (новичок — ворота, знаток — для сведения) и широкая разметка fvis.lua
local VL = require("tools.vislib").compute(lvl, G, def, good)
local FX = V.make(def)
local marks = { { "новичок" }, { "знаток" }, { "fvis" } }
local vis = { ["новичок"] = {}, ["знаток"] = {}, ["fvis"] = {} }
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] ~= 1 then
    vis["новичок"][i] = VL.newbie[i]
    vis["знаток"][i] = VL.expert[i]
    vis["fvis"][i] = washed(S[i]) or FX(lvl, S[i])
  end
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local onPath = {}
for idx, s in ipairs(path) do onPath[s] = idx - 1 end
-- расстояние от пути вперёд по графу и шаг пути, от которого ближе всего
local dist, from, q, h = {}, {}, {}, 1
for _, s in ipairs(path) do dist[s] = 0; from[s] = onPath[s]; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] == 0 then
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]; if dist[v] == nil then dist[v] = dist[u] + 1; from[v] = from[u]; q[#q + 1] = v end end
  end
end
local function branch(s, visM)
  local d, qq, hh, maxd = { [s] = 0 }, { s }, 1, 0
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    for e = ES[u - 1], ES[u] - 1 do
      local v = E[e]
      if d[v] == nil and G.flag[v] == 0 and good[v] ~= 1 and not visM[v] then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq + 1] = v end
    end
  end
  return #qq, maxd
end
local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local function X(st, q) return (R.xy(lvl, st.pos[q])) end
local function Y(st, q) local _, y = R.xy(lvl, st.pos[q]); return y end
local function cfg(st)
  local t = {}
  for qq, p in ipairs(P) do if p.movable then local cx, cy = R.xy(lvl, st.pos[qq]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, cx, cy, st.fixed[qq] and "F" or "") end end
  return "[" .. table.concat(t, " ") .. "]"
end
local classes = {
  { "очередь двинута к лифту раньше, чем в неё встал тройник: ниппель занял его место (ошибка подсказки №1)",
    function(st)
      local teeOut = not inCol(st.pos[k.tee]) and not (Y(st, k.tee) == qy and X(st, k.tee) > sx)
      return teeOut and not st.fixed[k.nip] and Y(st, k.nip) == qy and X(st, k.nip) < nx0
    end },
  { "тройник поехал лифтом первым и остался в стопке (заглушка под ним или его верх открыт у мойки)",
    function(st)
      local tc, pc = st.pos[k.tee], st.pos[k.plug]
      if not inCol(tc) then return false end
      if st.fixed[k.tee] then return not (st.fixed[k.plug] and pc == lvl.nb[tc][R.UP]) end
      return inCol(pc) and pc > tc
    end },
  { "заглушка поехала первой, а тройник ещё слева (обход без парома)",
    function(st) return inCol(st.pos[k.plug]) and X(st, k.tee) < sx end },
  { "ниппель в основании раньше тройника",
    function(st) return st.fixed[k.nip] and not inCol(st.pos[k.tee]) end },
}
for _, c in ipairs(classes) do
  local n, live, near, nearState = 0, 0, nil, nil
  for i = 1, G.n do
    if S[i] and c[2](S[i]) then
      n = n + 1
      if good[i] == 1 then live = live + 1 end
      if dist[i] and (near == nil or dist[i] < near) then near = dist[i]; nearState = i end
    end
  end
  print(c[1] .. ":")
  print(string.format("   состояний %d, живых %d; ближайшее — в %s ход(а) от пути (у шага %s), %s", n, live,
    tostring(near), nearState and tostring(from[nearState]) or "-", nearState and (good[nearState] == 1 and "живое" or "мёртвое") or "-"))
  for _, m in ipairs(marks) do
    local vm = vis[m[1]]
    local hid, vv, best = 0, 0, nil
    for i = 1, G.n do
      if S[i] and G.flag[i] == 0 and good[i] ~= 1 and c[2](S[i]) then
        if vm[i] then vv = vv + 1 else hid = hid + 1; if dist[i] and (best == nil or dist[i] < dist[best]) then best = i end end
      end
    end
    local line = string.format("   %-8s видимых %d, скрытых %d", m[1], vv, hid)
    if best then
      local bn, bd = branch(best, vm)
      line = line .. string.format("; ближайшее скрытое — в %d ход(а) от пути (у шага %d), глубина от старта %d, %s; скрытая ветка из него: %d сост., глубина %d",
        dist[best], from[best], G.depth[best], cfg(S[best]), bn, bd)
    end
    print(line)
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
