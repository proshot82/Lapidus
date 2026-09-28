-- verify.lua файл.lua — проверки кандидата семейства «стопка в лифте» (решений и кадров не печатает):
--  1) видимый проигрыш файла (mine) и широкий скептика (wide, vis.lua) не помечают ни одного живого состояния;
--  2) ловушки: сколько состояний, живых среди них (должно быть 0), видимых mine/wide, минимальное расстояние
--     от кратчайшего пути (в ходах) и глубина скрытой ветки из ближайшего такого состояния;
--  3) контрольные фильтры и мутации (должны оставаться решаемыми).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local wide = V.make("wide")
local k = {}
for q, p in ipairs(lvl.pieces) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end; if p.fixture then k.fix = q end end
local sx = R.xy(lvl, lvl.pieces[k.src].start)
local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local _, sy0 = R.xy(lvl, lvl.pieces[k.src].start)
-- «поднята лифтом»: в столбе выше верхней клетки струи от стояка (над основанием фонтана)
local function risen(c) if c == 0 or not inCol(c) then return false end local _, y = R.xy(lvl, c); return y < sy0 - lvl.R end
local function lostBy(f, st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return f(lvl, st)
end
local S, visM, visW = {}, {}, {}
local badM, badW = 0, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i]); S[i] = st
    if G.flag[i] ~= 1 then
      visM[i] = lostBy(def.visibleLoss, st); visW[i] = lostBy(wide, st)
      if good[i] == 1 and visM[i] then badM = badM + 1 end
      if good[i] == 1 and visW[i] then badW = badW + 1 end
    end
  end
end
print(string.format("1) живых, помеченных видимым проигрышем: mine %d, wide %d (должно быть 0)", badM, badW))
-- кратчайший путь и расстояния от него
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local dist, q, h = {}, {}, 1
for _, s in ipairs(path) do dist[s] = 0; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] == 0 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; q[#q + 1] = v end end
  end
end
local function hiddenDepth(from, vis)
  local d, qq, hh, maxd = { [from] = 0 }, { from }, 1, 0
  while hh <= #qq do
    local u = qq[hh]; hh = hh + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if d[v] == nil and G.flag[v] == 0 and good[v] ~= 1 and not vis[v] then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qq[#qq + 1] = v end
    end
  end
  return #qq, maxd
end
local traps = {
  { "тройник поднят лифтом раньше заглушки (ошибка подсказки №1, ложный план)", function(st) return risen(st.pos[k.tee]) and not inCol(st.pos[k.plug]) end },
  { "  то же, но Лапидус не над тройником в шахте (обычная ошибка: тройник первым, Лапидус внизу)", function(st)
      if not (risen(st.pos[k.tee]) and not inCol(st.pos[k.plug])) then return false end
      for _, c in ipairs(st.body) do if inCol(c) and c < st.pos[k.tee] then return false end end
      return true end },
  { "ниппель в фонтане, а тройник ещё не в лифте", function(st) return st.fixed[k.nip] and not inCol(st.pos[k.tee]) end },
  { "переходник поднят лифтом раньше тройника", function(st) return k.adp and risen(st.pos[k.adp]) and not inCol(st.pos[k.tee]) end },
  { "ниппель в фонтане, а переходник ещё не в лифте", function(st) return k.adp and st.fixed[k.nip] and not inCol(st.pos[k.adp]) end },
  { "тройник перенесён направо через столб", function(st) local c = st.pos[k.tee]; return c ~= 0 and not st.fixed[k.tee] and (R.xy(lvl, c)) > sx end },
}
print("2) ловушки:")
for _, t in ipairs(traps) do
  local n, live, vm, vw, best, bestD = 0, 0, 0, 0, nil, 1e9
  for i = 1, G.n do
    local st = S[i]
    if st and G.flag[i] == 0 and t[2](st) then
      n = n + 1
      if good[i] == 1 then live = live + 1 end
      if visM[i] then vm = vm + 1 end
      if visW[i] then vw = vw + 1 end
      if dist[i] and dist[i] < bestD and not visM[i] then bestD = dist[i]; best = i end
    end
  end
  local line = string.format("   %s: состояний %d, живых %d, видимых mine %d / wide %d", t[1], n, live, vm, vw)
  if best then
    local szM, dM = hiddenDepth(best, visM)
    local szW, dW = 0, 0
    if not visW[best] then szW, dW = hiddenDepth(best, visW) end
    line = line .. string.format("; ближайшее скрытое — в %d ход(а) от пути (шаг пути %s); скрытая ветка из него: mine %d сост., глубина %d; wide %d сост., глубина %d",
      bestD, tostring(G.depth[best] - bestD), szM, dM, szW, dW)
  end
  print(line)
end
SV.freeGraph(G); require("ffi").C.free(good)
-- 3) контрольные фильтры: должны оставаться решаемыми
local function solvable(d2, filter)
  local l2 = R.compile(d2)
  local G2 = SV.explore(l2, 3000000, filter)
  local ok = G2 and G2.firstWin ~= nil
  local mv = ok and G2.depth[G2.firstWin] or nil
  SV.freeGraph(G2)
  return ok, mv
end
local function strip(d) local d2 = SV.deepcopy(d); d2.ablations = nil; return d2 end
local controls = {
  { "детали не переходят на чужую сторону столба", function(l, st, ns)
      for qq, p in ipairs(l.pieces) do
        local c = ns.pos[qq]
        if p.movable and c ~= 0 and not ns.fixed[qq] then
          local cx = R.xy(l, c)
          local sx0 = R.xy(l, p.start)
          if cx ~= sx and ((sx0 < sx) ~= (cx < sx)) then return false end
        end
      end
      return true end },
  { "тройник въезжает в столб только с уступа (не держать его в столбе собой)", function(l, st, ns)
      local c = ns.pos[k.tee]
      if c ~= 0 and not ns.fixed[k.tee] and inCol(c) then
        local _, cy = R.xy(l, c)
        local _, sy = R.xy(l, l.pieces[k.src].start)
        if cy >= sy - 1 then return false end
      end
      return true end },
  { "Лапидус не заходит в столб, пока ниппель не вставлен", function(l, st, ns)
      if ns.fixed[k.nip] then return true end
      for _, c in ipairs(ns.body) do
        local cx, cy = R.xy(l, c)
        local _, sy = R.xy(l, l.pieces[k.src].start)
        if cx == sx and cy >= sy - 2 then return false end
      end
      return true end },
}
print("3) контроли (должны быть решаемы):")
for _, c in ipairs(controls) do
  local ok, mv = solvable(strip(def), c[2])
  print(string.format("   %s: %s%s", c[1], ok and "решаем" or "НЕРЕШАЕМ", mv and (" (" .. mv .. " ходов)") or ""))
end
local d4 = strip(def); d4.length = { d4.length[1], 4 }
local ok4, mv4 = solvable(d4)
print(string.format("   длина Лапидуса до 4: %s%s", ok4 and "решаем" or "НЕРЕШАЕМ", mv4 and (" (" .. mv4 .. " ходов)") or ""))
