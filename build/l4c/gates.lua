-- build/l4c/gates.lua — ворота кв. 4 сверх build/l6b/check.lua (28.09). Решений и кадров не печатает.
-- luajit build/l4c/gates.lua файл.lua [wide]
--   wide — вместо def.visibleLoss взять самую широкую честную версию (build/l4c/vis_wide.lua).
-- Печатает: метрики как check.lua (скрытые, умная обезьяна, глубина, прогулка), вынужденных подряд, выигрышных,
-- живых с пометкой «видимо проиграно» (должно быть 0), ошибку подсказки №1 (собранная заранее пара: достижима ли,
-- мертва ли, видима ли, как далеко от кратчайшего пути, глубина скрытой ветки), абляции уровня и контрольные фильтры.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local mode = arg[2] or "main"
local vis = def.visibleLoss
if mode == "wide" then vis = dofile("build/l4c/vis_wide.lua") elseif mode == "v3" then vis = dofile("build/l4c/vis_v3.lua") elseif mode == "seal" then vis = dofile("build/l4c/vis_seal.lua") end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G or not G.firstWin then print("НЕРЕШАЕМ") return end
local good = SV.goodSet(G)
local qc, qn, S
for q, p in ipairs(lvl.pieces) do
  if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end
  if p.source then S = p.start end
end
local B = lvl.nb[S][1]
local T = lvl.nb[B][1]
local states = {}
local function st(i) local s = states[i]; if not s then s = R.decode(lvl, G.keys[i]); states[i] = s end; return s end
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return vis and vis(lvl, s) or false
end
local live, visN, hid, washed, nwin, liveMarked = 0, 0, 0, 0, 0, 0
local hidden, isLost = {}, {}
for i = 1, G.n do
  if G.flag[i] == 1 then nwin = nwin + 1 end
  if G.flag[i] == 2 then washed = washed + 1 else
    local l = lost(st(i)); isLost[i] = l
    if good[i] == 1 then live = live + 1; if l then liveMarked = liveMarked + 1 end
    elseif l then visN = visN + 1 else hid = hid + 1; hidden[i] = true end
  end
end
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
local function objs(i) local s = st(i); local t = {}; for q = 1, #s.pos do t[#t + 1] = s.pos[q] .. (s.fixed[q] and "f" or "") end; return table.concat(t, ",") end
local streak, maxStreak, events, run1, maxRun1 = 0, 0, 0, 0, 0
local safeSeq = {}
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  safeSeq[#safeSeq + 1] = safe
  if safe == 1 then run1 = run1 + 1; if run1 > maxRun1 then maxRun1 = run1 end else run1 = 0 end
  if objs(path[i]) ~= objs(path[i + 1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
end
print(string.format("[%s] ходов %d | состояний %d (живых %d, видимых %d, скрытых %d, смыт %d) | выигрышных %d | живых с пометкой видимого %d",
  mode, opt, G.n, live, visN, hid, washed, nwin, liveMarked))
print(string.format("[%s] СКРЫТЫХ %.0f %% | УМНАЯ ОБЕЗЬЯНА %.3f %% | ГЛУБИНА %d у пути [%s]",
  mode, 100 * hid / math.max(1, hid + live), smart, maxDeep, table.concat(dl, " ")))
print(string.format("[%s] событий %d, прогулка %d, вынужденных подряд %d", mode, events, maxStreak, maxRun1))
-- ошибка подсказки №1: собранная заранее пара (муфта и ниппель свинчены, не закреплены)
local dist, q, h = {}, {}, 1
for _, s in ipairs(path) do dist[s] = 0; q[#q + 1] = s end
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] ~= 2 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; q[#q + 1] = v end end
  end
end
local pairN, pairLive, pairVis, best, bestD = 0, 0, 0, nil, 1e9
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local s = st(i)
    if s.pos[qc] ~= 0 and s.pos[qn] ~= 0 and not s.fixed[qc] and s.asm[qc] == s.asm[qn] then
      pairN = pairN + 1
      if good[i] == 1 then pairLive = pairLive + 1 end
      if isLost[i] then pairVis = pairVis + 1 end
      if dist[i] and dist[i] < bestD then bestD = dist[i]; best = i end
    end
  end
end
-- мёртвые состояния без пары, из которых ещё можно прийти к сборке (обратный обход от пар по мёртвым состояниям)
local rev = {}
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] ~= 1 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local v = G.edges.p[e]
      rev[v] = rev[v] or {}; rev[v][#rev[v] + 1] = i
    end
  end
end
local isPair = {}
local preSeen, pq, ph = {}, {}, 1
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local s = st(i)
    if s.pos[qc] ~= 0 and s.pos[qn] ~= 0 and not s.fixed[qc] and s.asm[qc] == s.asm[qn] then isPair[i] = true; preSeen[i] = true; pq[#pq + 1] = i end
  end
end
while ph <= #pq do
  local u = pq[ph]; ph = ph + 1
  for _, v in ipairs(rev[u] or {}) do if not preSeen[v] then preSeen[v] = true; pq[#pq + 1] = v end end
end
local preN, preHid = 0, 0
for i in pairs(preSeen) do if not isPair[i] then preN = preN + 1; if hidden[i] then preHid = preHid + 1 end end end
print(string.format("[%s] подсказка №1 «собрать заранее»: пар %d, живых %d, видимых %d, скрытых %d; ближайшая в %s ходах от пути",
  mode, pairN, pairLive, pairVis, pairN - pairVis - pairLive, tostring(best and bestD)))
if best then
  -- скрытая ветка, в которой лежит ближайшая пара: вход с пути и глубина
  local inBranch = {}
  for i in pairs(hidden) do inBranch[i] = true end
  local comp, qq, hh = { [best] = true }, { best }, 1
  -- ищем состояния пути, из которых одним ходом попадают в скрытую область, достигающую пары
  local entryStep, entryDepth, entrySize = nil, 0, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then
        -- достигает ли эта ветка пары, не выходя из скрытых?
        local seen, q2, h2, hasPair = { [j] = true }, { j }, 1, false
        while h2 <= #q2 do
          local u = q2[h2]; h2 = h2 + 1
          local su = st(u)
          if su.asm[qc] == su.asm[qn] and not su.fixed[qc] and su.pos[qc] ~= 0 then hasPair = true end
          for e2 = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
            local v = G.edges.p[e2]
            if hidden[v] and not seen[v] then seen[v] = true; q2[#q2 + 1] = v end
          end
        end
        if hasPair and not entryStep then
          entryStep = k - 1
          entryDepth, entrySize = depthFrom(j, hidden)
        end
      end
    end
  end
  -- траектория ошибки: от кратчайшего пути до ближайшей пары, статусы состояний (без кадров)
  local par, q3, h3 = {}, {}, 1
  for _, s0 in ipairs(path) do par[s0] = 0; q3[#q3 + 1] = s0 end
  while h3 <= #q3 do
    local u = q3[h3]; h3 = h3 + 1
    if G.flag[u] ~= 2 then
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if par[v] == nil then par[v] = u; q3[#q3 + 1] = v end end
    end
  end
  local tr, y = {}, best
  while y ~= 0 do
    table.insert(tr, 1, good[y] == 1 and "живое" or (isLost[y] and (isPair[y] and "ВИДИМОЕ(пара)" or "ВИДИМОЕ") or (isPair[y] and "скрытое(пара)" or "скрытое")))
    y = par[y]
  end
  print(string.format("[%s]   траектория ошибки от пути до пары: %s", mode, table.concat(tr, " → ")))
  -- ближайшая СКРЫТАЯ пара и траектория к ней
  local bestH, bestHD = nil, 1e9
  for i in pairs(isPair) do if hidden[i] and dist[i] and dist[i] < bestHD then bestHD = dist[i]; bestH = i end end
  if bestH then
    local tr2, y2 = {}, bestH
    while y2 ~= 0 do
      table.insert(tr2, 1, good[y2] == 1 and "живое" or (isLost[y2] and (isPair[y2] and "ВИДИМОЕ(пара)" or "ВИДИМОЕ") or (isPair[y2] and "скрытое(пара)" or "скрытое")))
      y2 = par[y2]
    end
    local dH, nH = depthFrom(bestH, hidden)
    print(string.format("[%s]   ближайшая СКРЫТАЯ пара в %d ходах от пути: %s; из неё скрытая область глубиной %d (%d сост.)", mode, bestHD, table.concat(tr2, " → "), dH, nH))
  else
    print(string.format("[%s]   скрытых пар нет", mode))
  end
  print(string.format("[%s]   скрытая ветка, ведущая к сборке: вход после хода %s, глубина %d, состояний %d; мёртвых до сборки, откуда к ней можно прийти, %d (скрытых %d)",
    mode, tostring(entryStep), entryDepth, entrySize, preN, preHid))
end
SV.freeGraph(G); require("ffi").C.free(good)
if mode ~= "main" then return end
-- абляции уровня и контрольные фильтры (должны оставаться решаемыми)
local abl = SV.ablations(def, { cap = 3000000 })
local ab = {}
for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
print("абляции: " .. table.concat(ab, ", "))
local E
for qq2, pp in ipairs(lvl.pieces) do if pp.kind == "pipe" then E = qq2 end end
local controls = {
  { "контроль: пары вне шахты не бывает (сборка заранее запрещена)", function(l, s, ns)
      return not (ns.pos[qc] ~= 0 and ns.pos[qn] ~= 0 and ns.asm[qc] == ns.asm[qn] and not ns.fixed[qc]) end },
  { "контроль: ниппель не входит в шахту раньше муфты", function(l, s, ns)
      return not ((ns.pos[qn] == T or ns.pos[qn] == B) and not ns.fixed[qc]) end },
  { "контроль: Лапидус не держится за отвод, пока муфта не на месте", function(l, s, ns)
      if ns.fixed[qc] or ns.dead then return true end
      local occ = R.occupancy(ns)
      return R.endScrew(l, ns, occ, "head") ~= E and R.endScrew(l, ns, occ, "heel") ~= E end },
}
for _, c in ipairs(controls) do
  local G2 = SV.explore(lvl, 3000000, c[2])
  print(string.format("%s: %s", c[1], G2 and G2.firstWin and ("решаем за " .. G2.depth[G2.firstWin]) or "НЕРЕШАЕМ"))
  SV.freeGraph(G2)
end
