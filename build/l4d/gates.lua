-- build/l4d/gates.lua файл.lua — ворота кв. 4 сверх build/l6b/check.lua (общая линейка tools/vislib.lua). Решений не печатает.
-- Печатает: вынужденных ходов подряд, живых с пометкой «видимо проиграно», ошибку подсказки №1 (собранная заранее
-- пара: достижима ли, скрыта ли, расстояние от кратчайшего пути, глубина скрытой области), абляции уровня и
-- контрольные фильтры (должны оставаться решаемыми — узость фильтра роли).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G or not G.firstWin then print("НЕРЕШАЕМ") return end
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local qc, qn, S, hole
for q, p in ipairs(lvl.pieces) do
  if p.what == "coupling" then qc = q elseif p.movable then qn = q end
  if p.source then S = p.start end
end
local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
local W = lvl.W
local hidden, live, liveMarked = {}, 0, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    if good[i] == 1 then live = live + 1; if VL.newbie[i] then liveMarked = liveMarked + 1 end
    elseif not VL.newbie[i] then hidden[i] = true end
  end
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local run1, maxRun1 = 0, 0
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  if safe == 1 then run1 = run1 + 1; if run1 > maxRun1 then maxRun1 = run1 end else run1 = 0 end
end
print(string.format("вынужденных ходов подряд %d (≤3) | живых с пометкой видимого %d (=0) | выигрышных %d", maxRun1, liveMarked, (function() local n = 0 for i = 1, G.n do if G.flag[i] == 1 then n = n + 1 end end return n end)()))
-- расстояние от кратчайшего пути
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
local function isPair(s) return s.pos[qc] ~= 0 and s.pos[qn] ~= 0 and not s.fixed[qc] and s.asm[qc] == s.asm[qn] end
local pairN, pairHid, pairVis, best, bestD = 0, 0, 0, nil, 1e9
for i = 1, G.n do
  if G.flag[i] ~= 2 and isPair(VL.states[i]) then
    pairN = pairN + 1
    if hidden[i] then pairHid = pairHid + 1; if dist[i] and dist[i] < bestD then bestD = dist[i]; best = i end
    elseif good[i] ~= 1 then pairVis = pairVis + 1 end
  end
end
print(string.format("подсказка №1 «собрать заранее»: пар %d (живых %d, скрытых %d, видимых %d); ближайшая скрытая пара в %s ходах от пути%s",
  pairN, pairN - pairHid - pairVis, pairHid, pairVis, tostring(best and bestD), best and string.format(", из неё скрытая область глубиной %d (%d сост.)", depthFrom(best)) or ""))
-- ошибки первого хода с кратчайшего пути: куда ведут скрытые ветки (по классам)
local cls = {}
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if hidden[j] then
      local st = VL.states[j]
      local name
      if isPair(st) then name = "пара"
      elseif st.fixed[qc] and st.pos[qc] ~= B then name = "муфта на чужом отводе"
      elseif st.fixed[qn] and st.pos[qn] ~= T then name = "ниппель на чужом отводе"
      elseif st.fixed[qn] and st.pos[qn] == T and not st.fixed[qc] then name = "ниппель в шахте раньше муфты"
      else name = "порядок на полу / ниппель уронен раньше" end
      local d = depthFrom(j)
      local c = cls[name] or { first = k - 1, depth = 0 }; cls[name] = c
      if d > c.depth then c.depth = d end
    end
  end
end
for name, c in pairs(cls) do print(string.format("  скрытая ошибка с пути: %-40s вход после хода %2d, глубина %d", name, c.first, c.depth)) end
SV.freeGraph(G); require("ffi").C.free(good)
-- абляции и контрольные фильтры
local abl = SV.ablations(def, { cap = 3000000 })
local ab = {}
for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
print("абляции: " .. table.concat(ab, ", "))
local stubs = {}
for q, p in ipairs(lvl.pieces) do if p.kind == "stub" then stubs[#stubs + 1] = q end end
local controls = {
  { "контроль: пары вне шахты не бывает", function(l, s, ns) return not isPair(ns) end },
  { "контроль: без толчка цепочкой (обе детали не двигаются одним ходом)", function(l, s, ns)
      return not (not s.fixed[qc] and not s.fixed[qn] and s.pos[qc] ~= ns.pos[qc] and s.pos[qn] ~= ns.pos[qn]) end },
  { "контроль: ниппель не входит в шахту раньше муфты", function(l, s, ns)
      return not ((ns.pos[qn] == T or ns.pos[qn] == B) and not ns.fixed[qc]) end },
  { "контроль: детали не прикручиваются к глухим отводам", function(l, s, ns)
      for _, q in ipairs({ qc, qn }) do
        if ns.fixed[q] and ns.pos[q] ~= B and ns.pos[q] ~= T then return false end
      end
      return true end },
  { "контроль: Лапидус не пользуется люком (6,4)", function(l, s, ns)
      local c = R.idx(l, 6, 4)
      for _, b in ipairs(ns.body) do if b == c then return false end end
      return true end },
  { "контроль: Лапидус не заходит в правый колодец (x=10)", function(l, s, ns)
      for _, b in ipairs(ns.body) do local x = R.xy(l, b); if x == 10 then return false end end
      return true end },
  { "контроль: муфту не двигают вправо по антресоли", function(l, s, ns)
      local x0, y0 = R.xy(l, s.pos[qc]); local x1, y1 = R.xy(l, ns.pos[qc])
      return not (y0 == 3 and y1 == 3 and x1 > x0) end },
}
for _, c in ipairs(controls) do
  local G2 = SV.explore(lvl, 3000000, c[2])
  print(string.format("%s: %s", c[1], G2 and G2.firstWin and ("решаем за " .. G2.depth[G2.firstWin]) or "НЕРЕШАЕМ"))
  SV.freeGraph(G2)
end
