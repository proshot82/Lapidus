-- build/l5c/gates.lua — ворота кв. 5 сверх build/l6b/check.lua (29.09). Решений и кадров НЕ печатает.
-- luajit build/l5c/gates.lua файл.lua [novice|expert]
--   novice (по умолчанию) — def.visibleLoss (мерка новичка); expert — build/l5c/vis_expert.lua (мерка «знатока»).
-- Печатает: метрики (скрытые, умная обезьяна, глубина), вынужденных подряд, прогулку, выигрышных конфигураций,
-- «живых с пометкой видимого» (должно быть 0), классы скрытых тупиков (по конфигурациям деталей), ошибку
-- подсказки №1 («заглушка ушла к месту раньше, чем послужила лестницей»: тройник ещё не на стояке, а заглушке
-- статически уже не вернуться в стартовую клетку) — достижима ли, живая/скрытая/видимая, вход с пути, глубина.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local mode = arg[2] or "novice"
local vis = def.visibleLoss
if mode == "expert" then vis = dofile("build/l5c/vis_expert.lua") end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G or not G.firstWin then print("НЕРЕШАЕМ") return end
local good = SV.goodSet(G)
local qt, qp, src
for q, p in ipairs(lvl.pieces) do
  if p.what == "tee" then qt = q elseif p.what == "plug" then qp = q elseif p.source then src = q end
end
local sd
for d = 1, 4 do if lvl.pieces[src].ports[d] then sd = d end end
local Tcell = lvl.nb[lvl.pieces[src].start][sd]
local Pcell = lvl.nb[Tcell][4]
local plugStart = lvl.pieces[qp].start
local states = {}
local function st(i) local s = states[i]; if not s then s = R.decode(lvl, G.keys[i]); states[i] = s end; return s end
local function lost(s)
  if not def.washOk then for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end end
  return vis and vis(lvl, s) or false
end
local live, visN, hid, washed, nwin, liveMarked = 0, 0, 0, 0, 0, 0
local hidden, isLost = {}, {}
local winCfg = {}
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t + 1] = p.tag .. "=смыт" else
      local x, y = R.xy(lvl, s.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
for i = 1, G.n do
  if G.flag[i] == 1 then nwin = nwin + 1; winCfg[cfg(st(i))] = true end
  if G.flag[i] == 2 then washed = washed + 1 else
    local l = lost(st(i)); isLost[i] = l
    if good[i] == 1 then live = live + 1; if l then liveMarked = liveMarked + 1 end
    elseif l then visN = visN + 1 else hid = hid + 1; hidden[i] = true end
  end
end
local nWinCfg = 0
for _ in pairs(winCfg) do nWinCfg = nWinCfg + 1 end
local opt = G.depth[G.firstWin]
local Tn = 5 * opt
local p, ok = { [1] = 1.0 }, 0
for _ = 1, Tn do
  local np = {}
  for i, pr in pairs(p) do
    local cand = {}
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not isLost[j] then cand[#cand + 1] = j end
    end
    if #cand == 0 then np[i] = (np[i] or 0) + pr else
      local share = pr / #cand
      for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
    end
  end
  p = np
end
local smart = 100 * (1 - (1 - ok) ^ (1000 / Tn))
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function depthFrom(j, set)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if set[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd, #q
end
local maxDeep, deepAt = 0, {}
for k = 1, #path - 1 do
  local s = path[k]
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local j = G.edges.p[e]
    if hidden[j] then local d = depthFrom(j, hidden); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
  end
end
local dl = {}
for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
local function objs(i) local s = st(i); local t = {}; for q = 1, #s.pos do t[#t + 1] = s.pos[q] .. (s.fixed[q] and "f" or "") .. s.asm[q] end; return table.concat(t, ",") end
local streak, maxStreak, events, run1, maxRun1 = 0, 0, 0, 0, 0
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  if safe == 1 then run1 = run1 + 1; if run1 > maxRun1 then maxRun1 = run1 end else run1 = 0 end
  if objs(path[i]) ~= objs(path[i + 1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
end
print(string.format("[%s] ходов %d | состояний %d (живых %d, видимых %d, скрытых %d, смыт %d) | выигрышных состояний %d, конфигураций %d | живых с пометкой видимого %d",
  mode, opt, G.n, live, visN, hid, washed, nwin, nWinCfg, liveMarked))
print(string.format("[%s] СКРЫТЫХ %.1f %% | УМНАЯ ОБЕЗЬЯНА %.3f %% | ГЛУБИНА %d у пути [%s]",
  mode, 100 * hid / math.max(1, hid + live), smart, maxDeep, table.concat(dl, " ")))
print(string.format("[%s] событий %d, прогулка %d, вынужденных подряд %d", mode, events, maxStreak, maxRun1))
-- классы скрытых тупиков по конфигурациям деталей
local agg = {}
for i in pairs(hidden) do local k = cfg(st(i)); agg[k] = (agg[k] or 0) + 1 end
local list = {}
for k, v in pairs(agg) do list[#list + 1] = { k, v } end
table.sort(list, function(a, b) return a[2] > b[2] end)
local parts = {}
for i = 1, math.min(12, #list) do parts[#parts + 1] = list[i][1] .. ": " .. list[i][2] end
print(string.format("[%s] скрытые по конфигурациям деталей: %s", mode, table.concat(parts, "; ")))
-- ошибка подсказки №1: заглушка ушла к месту (статически не вернуться в стартовую клетку), пока тройник не на стояке
local function staticBack(s)
  local fixedAt = {}
  for q = 1, #s.pos do if s.pos[q] ~= 0 and s.fixed[q] then fixedAt[s.pos[q]] = true end end
  local function solid(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] end
  local function pit(c) return c ~= 0 and lvl.cell[c] == 2 end
  local function pusherOK(t, c)
    if solid(t) or pit(t) then return false end
    for d = 1, 4 do local u = lvl.nb[t][d]; if u ~= 0 and u ~= c and not solid(u) and not pit(u) then return true end end
    return false
  end
  local function fall(c) while true do local b = lvl.nb[c][3]; if solid(b) then return c end; if pit(b) then return 0 end; c = b end end
  local c0 = s.pos[qp]
  local seen, q, h = { [c0] = true }, { c0 }, 1
  while h <= #q do
    local c = q[h]; h = h + 1
    if c == plugStart then return true end
    for _, d in ipairs({ 2, 4 }) do
      local t = lvl.nb[c][d]; local back = lvl.nb[c][d == 2 and 4 or 2]
      if t ~= 0 and not solid(t) and not pit(t) and pusherOK(back, c) then
        local r = fall(t)
        if r ~= 0 and not seen[r] then seen[r] = true; q[#q + 1] = r end
      end
    end
  end
  return false
end
local function hint1(s)
  if s.pos[qp] == 0 or s.pos[qt] == 0 then return false end
  if s.fixed[qt] and s.pos[qt] == Tcell then return false end
  if s.fixed[qp] then return true end
  return not staticBack(s)
end
local dist, qq, hh = {}, {}, 1
for _, s0 in ipairs(path) do dist[s0] = 0; qq[#qq + 1] = s0 end
local par = {}
for _, s0 in ipairs(path) do par[s0] = 0 end
while hh <= #qq do
  local u = qq[hh]; hh = hh + 1
  if G.flag[u] ~= 2 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; par[v] = u; qq[#qq + 1] = v end end
  end
end
local hN, hLive, hHid, hVis, best, bestD = 0, 0, 0, 0, nil, 1e9
local hcfg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and hint1(st(i)) then
    hN = hN + 1
    if good[i] == 1 then hLive = hLive + 1 elseif hidden[i] then hHid = hHid + 1 else hVis = hVis + 1 end
    if hidden[i] then hcfg[cfg(st(i))] = true end
    if hidden[i] and dist[i] and dist[i] < bestD then bestD = dist[i]; best = i end
  end
end
local hc = {}
for k in pairs(hcfg) do hc[#hc + 1] = k end
table.sort(hc)
print(string.format("[%s] подсказка №1 «заглушка к месту раньше лестницы»: состояний %d — живых %d, скрытых %d, видимых %d; конфигураций (скрытых): %s",
  mode, hN, hLive, hHid, hVis, table.concat(hc, " | ")))
if best then
  local tr, y = {}, best
  while y ~= 0 do
    table.insert(tr, 1, good[y] == 1 and "живое" or (isLost[y] and "ВИДИМОЕ" or (hint1(st(y)) and "скрытое(ошибка)" or "скрытое")))
    y = par[y]
  end
  local dH, nH = depthFrom(best, hidden)
  -- с какого хода кратчайшего пути ближайшая такая ошибка
  local y2, onPathStep = best, nil
  while par[y2] and par[y2] ~= 0 do y2 = par[y2] end
  for k, s0 in ipairs(path) do if s0 == y2 then onPathStep = k - 1 end end
  print(string.format("[%s]   ближайшее скрытое состояние ошибки: %d ход(а) от пути (после хода %s пути); статусы по дороге: %s; скрытая область из него: глубина %d, %d сост.",
    mode, bestD, tostring(onPathStep), table.concat(tr, " → "), dH, nH))
end
SV.freeGraph(G); require("ffi").C.free(good)
