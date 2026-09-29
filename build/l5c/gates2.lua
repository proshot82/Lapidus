-- build/l5c/gates2.lua файл.lua — ворота по ОБЩЕЙ линейке (tools/vislib.lua) сверх build/l6b/check.lua.
-- Решений и кадров не печатает. Печатает: вынужденных подряд (живых ходов ровно 1), выигрышных конфигураций,
-- ошибку подсказки №1 («заглушка у гнезда/в гнезде раньше тройника»: тройник не на стояке, заглушка статически
-- уже не вернётся в стартовую клетку) — сколько состояний, живых/скрытых (новичок)/видимых, скрытых для знатока,
-- вход с кратчайшего пути и глубина скрытой области; классы скрытых тупиков по конфигурациям деталей.
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
local qt, qp, src
for q, p in ipairs(lvl.pieces) do
  if p.what == "tee" then qt = q elseif p.what == "plug" then qp = q elseif p.source then src = q end
end
local sd
for d = 1, 4 do if lvl.pieces[src].ports[d] then sd = d end end
local Tcell = lvl.nb[lvl.pieces[src].start][sd]
local plugStart = lvl.pieces[qp].start
local st = VL.states
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t + 1] = p.tag .. "=смыт" else
      local x, y = R.xy(lvl, s.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local hidden, hiddenX = {}, {}
local winCfg, nWinCfg = {}, 0
for i = 1, G.n do
  if G.flag[i] == 1 then local k = cfg(st[i]); if not winCfg[k] then winCfg[k] = true; nWinCfg = nWinCfg + 1 end end
  if G.flag[i] ~= 2 and good[i] ~= 1 then
    if not VL.newbie[i] then hidden[i] = true end
    if not VL.expert[i] then hiddenX[i] = true end
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
print(string.format("ходов %d | выигрышных конфигураций %d | вынужденных подряд %d", G.depth[G.firstWin], nWinCfg, maxRun1))
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
-- статическая «возвратность» заглушки в стартовую клетку
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
local dist, par, qq, hh = {}, {}, {}, 1
for _, s0 in ipairs(path) do dist[s0] = 0; par[s0] = 0; qq[#qq + 1] = s0 end
while hh <= #qq do
  local u = qq[hh]; hh = hh + 1
  if G.flag[u] ~= 2 then
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]; if dist[v] == nil then dist[v] = dist[u] + 1; par[v] = u; qq[#qq + 1] = v end end
  end
end
local n, lv, hd, hdX, vs, best, bestD = 0, 0, 0, 0, 0, nil, 1e9
local cfgs = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and st[i] and hint1(st[i]) then
    n = n + 1
    if good[i] == 1 then lv = lv + 1 elseif hidden[i] then hd = hd + 1; cfgs[cfg(st[i])] = true else vs = vs + 1 end
    if hiddenX[i] then hdX = hdX + 1 end
    if hidden[i] and dist[i] and dist[i] < bestD then bestD = dist[i]; best = i end
  end
end
local cl = {}
for k in pairs(cfgs) do cl[#cl + 1] = k end
table.sort(cl)
print(string.format("подсказка №1 «заглушка к гнезду раньше лестницы»: состояний %d — живых %d, скрытых %d (из них скрытых и для знатока %d), видимых %d",
  n, lv, hd, hdX, vs))
print("  конфигурации (скрытые): " .. table.concat(cl, " | "))
if best then
  local y, onPath = best, nil
  while par[y] and par[y] ~= 0 do y = par[y] end
  for k, s0 in ipairs(path) do if s0 == y then onPath = k - 1 end end
  local dH, nH = depthFrom(best, hidden)
  print(string.format("  ближайшее скрытое: %d ход(а) от пути (после хода %s пути); скрытая область из него: глубина %d, %d сост.",
    bestD, tostring(onPath), dH, nH))
end
-- классы скрытых тупиков
local agg, aggX = {}, {}
for i in pairs(hidden) do local k = cfg(st[i]); agg[k] = (agg[k] or 0) + 1; if hiddenX[i] then aggX[k] = (aggX[k] or 0) + 1 end end
local list = {}
for k, v in pairs(agg) do list[#list + 1] = { k, v } end
table.sort(list, function(a, b) return a[2] > b[2] end)
for i = 1, math.min(10, #list) do print(string.format("  скрытые: %-34s %5d (для знатока скрыты %d)", list[i][1], list[i][2], aggX[list[i][1]] or 0)) end
SV.freeGraph(G); require("ffi").C.free(good)
