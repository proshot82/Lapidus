-- build/l6c/a_f2plus/review_file.lua — tools/review.lua для файла кандидата (путь вместо номера квартиры)
-- tools/review.lua — «честные» метрики коварства (26.09.2026, после разбора кв. 1–6).
-- luajit tools/review.lua 1 2 3 ...
-- Видимый проигрыш: смыт Лапидус или подвижная деталь, либо def.visibleLoss(lvl, st) (свой признак уровня,
-- например «ниппель лежит на полу» в кв. 6). Скрытый тупик: выиграть уже нельзя, но видимо ничего не потеряно.
-- «Умная обезьяна»: случайный игрок, который не делает видимо проигрышных ходов (5×opt ходов, перезапуски, 1000 ходов).
-- Компоненты скрытых тупиков: размер, с какого хода кратчайшего пути в них входят, глубина блуждания от входа.
-- Узкие места: состояния кратчайшего пути, без которых выигрыш недостижим вовсе.
-- Предлагаемые ворота (Lao согласился 26.09): скрытых ≥ 40 %, умная обезьяна ≤ 0,1–0,2 %, ≥ 1 ложная ветка
-- глубиной ≥ 8 ходов у пути, и ошибка из подсказки №1 достижима и ведёт в тупик (проверять руками, см. build/l6/claims.lua).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
for _, a in ipairs(arg) do
  local id = a
  local def = dofile(a)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local good = SV.goodSet(G)
  local states = {}
  local function lost(st)
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
    return def.visibleLoss and def.visibleLoss(lvl, st) or false
  end
  local live, vis, hid, washed = 0, 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] == 2 then washed = washed + 1 else
      local st = R.decode(lvl, G.keys[i]); states[i] = st
      if good[i] == 1 then live = live + 1 elseif lost(st) then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost(states[j]) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  -- путь
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  -- компоненты скрытых тупиков (неориентированно)
  local adj, comp, sizes, nc = {}, {}, {}, 0
  for i in pairs(hidden) do
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then adj[i] = adj[i] or {}; adj[j] = adj[j] or {}; table.insert(adj[i], j); table.insert(adj[j], i) end
    end
  end
  for i in pairs(hidden) do
    if not comp[i] then
      nc = nc + 1; comp[i] = nc
      local q, h = { i }, 1
      while h <= #q do local u = q[h]; h = h + 1; for _, v in ipairs(adj[u] or {}) do if not comp[v] then comp[v] = nc; q[#q + 1] = v end end end
      sizes[nc] = #q
    end
  end
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd
  end
  local entry, deep = {}, {}
  for k = 1, #path - 1 do
    local s = path[k]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then
        local c = comp[j]
        entry[c] = entry[c] or (k - 1)
        deep[c] = math.max(deep[c] or 0, depthFrom(j))
      end
    end
  end
  local maxDeep, firstEntry = 0, nil
  for c, d in pairs(deep) do if d > maxDeep then maxDeep = d end; if not firstEntry or entry[c] < firstEntry then firstEntry = entry[c] end end
  -- узкие места
  local function reachableWithout(ban)
    local seen, q, h = { [1] = true }, { 1 }, 1
    while h <= #q do
      local u = q[h]; h = h + 1
      if G.flag[u] == 1 then return true end
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if v ~= ban and not seen[v] and G.flag[v] ~= 2 then seen[v] = true; q[#q + 1] = v end
      end
    end
    return false
  end
  local bott = {}
  for k = 2, #path - 1 do if not reachableWithout(path[k]) then bott[#bott + 1] = k - 1 end end
  print(string.format("%s «%s»: ходов %d; состояний %d: живых %d, видимых потерь %d, скрытых тупиков %d, смыт Лапидус %d",
    id, def.name, opt, G.n, live, vis, hid, washed))
  print(string.format("   скрытых тупиков %.0f %%; умная обезьяна %.2f %% за 1000 ходов; компонент скрытых тупиков %d; самая глубокая ветка у пути ≈ %d ходов (первый вход после хода %s); узких мест %d%s",
    100 * hid / math.max(1, hid + live), smart, nc, maxDeep, tostring(firstEntry), #bott, #bott > 0 and (" (ходы " .. table.concat(bott, ",") .. ")") or ""))
  SV.freeGraph(G); require("ffi").C.free(good)
end
