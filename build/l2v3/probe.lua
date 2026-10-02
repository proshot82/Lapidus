-- build/l2v3/probe.lua — слепая проверка build/l2e/k6.lua (скептик-3, 29.09). Печатает только метрики, без ходов.
-- luajit build/l2v3/probe.lua [файл]
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local file = arg[1] or "build/l2e/k6.lua"
local def = dofile(file)
def.visibleLoss = def.visibleLoss or function(l, s) return s.dead end
def.hintError = def.hintError or function() return false end
local lvl = R.compile(def)
local W = lvl.W
local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end

local function anchors(st)
  if st.dead then return {} end
  local piece = R.occupancy(st)
  local t = {}
  for _, w in ipairs({ "head", "heel" }) do
    local q = R.endScrew(lvl, st, piece, w)
    if q then t[#t + 1] = (lvl.pieces[q].tag or lvl.pieces[q].kind) .. ":" .. w end
  end
  return t
end
local function anchorKey(st) local a = anchors(st); table.sort(a); return table.concat(a, ",") end
-- область: где тело
local function region(st)
  if st.dead then return "смыт" end
  local minx, maxx, miny, maxy = 99, 0, 99, 0
  for _, c in ipairs(st.body) do local x, y = xy(c)
    minx = math.min(minx, x); maxx = math.max(maxx, x); miny = math.min(miny, y); maxy = math.max(maxy, y) end
  if minx >= 6 then
    if maxy <= 2 then return "гребень" end
    if miny >= 6 then return "колодец низ (y≥6)" end
    return "колодец (y≤5)"
  end
  if maxx <= 4 then
    if miny >= 6 then return "шахта низ (y≥6)" end
    return "шахта (y≤5)"
  end
  return "лаз (тело в x=5)"
end
-- граф
local s0 = R.newState(lvl)
local idx, sts, succ, win, par, dist = {}, {}, {}, {}, {}, {}
local function add(s) local k = R.key(s); local i = idx[k]; if not i then i = #sts + 1; idx[k] = i; sts[i] = s end; return i end
add(s0); dist[1] = 0
local h = 1
while h <= #sts do
  local s = sts[h]
  win[h] = (not s.dead) and R.isWin(lvl, s)
  local out = {}
  if not s.dead and not win[h] then
    for m = 1, 8 do
      local tr = {}
      local ns = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir, tr)
      if ns then
        local j = add(ns)
        if not dist[j] then dist[j] = dist[h] + 1; par[j] = h end
        local b0 = tr[1].state.body; local fell = ns.dead
        if not fell then for k = 1, #b0 do if b0[k] ~= ns.body[k] then fell = true end end; if #b0 ~= #ns.body then fell = true end end
        out[#out + 1] = { j = j, m = m, fall = fell }
      end
    end
  end
  succ[h] = out; h = h + 1
end
local n = #sts
local rev = {}
for i = 1, n do for _, e in ipairs(succ[i]) do rev[e.j] = rev[e.j] or {}; table.insert(rev[e.j], i) end end
local live, q = {}, {}
for i = 1, n do if win[i] then live[i] = true; q[#q + 1] = i end end
local qh = 1
while qh <= #q do local j = q[qh]; qh = qh + 1; for _, i in ipairs(rev[j] or {}) do if not live[i] then live[i] = true; q[#q + 1] = i end end end
local goal; for i = 1, n do if win[i] then goal = i end end
local path = {}; do local x = goal; while x do table.insert(path, 1, x); x = par[x] end end
local opt = #path - 1
local dead = {}
local nlive, ndead, nwash = 0, 0, 0
for i = 1, n do if sts[i].dead then nwash = nwash + 1 elseif live[i] then nlive = nlive + 1 else ndead = ndead + 1; dead[i] = true end end
print(string.format("%s: состояний %d, кратчайшее %d, живых %d, мёртвых %d, смыт %d", file, n, opt, nlive, ndead, nwash))

-- замыкание вперёд
local function closure(i, only)
  local seen, qq, hh = { [i] = 0 }, { i }, 1
  while hh <= #qq do local u = qq[hh]; hh = hh + 1
    for _, e in ipairs(succ[u]) do if not seen[e.j] and (not only or only[e.j]) then seen[e.j] = seen[u] + 1; qq[#qq + 1] = e.j end end end
  return qq, seen
end

-- 1. мерки
local function pct(vis) local hid = 0; for i in pairs(dead) do if not vis(i) then hid = hid + 1 end end; return hid, 100 * hid / (hid + nlive) end
local function flip(st)
  local s = R.clone(st); local b, m = s.body, #s.body
  for i = 1, math.floor(m / 2) do b[i], b[m + 1 - i] = b[m + 1 - i], b[i] end
  R.settle(lvl, s); return s
end
local function flipLive(i)
  local fs = flip(sts[i]); local j = idx[R.key(fs)]
  if j then return live[j] and true or false end
  local seen, qq, hh = { [R.key(fs)] = true }, { fs }, 1
  while hh <= #qq and #qq < 50000 do local s = qq[hh]; hh = hh + 1
    if not s.dead then if R.isWin(lvl, s) then return true end
      for m = 1, 8 do local ns = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir)
        if ns then local k = R.key(ns); if not seen[k] then seen[k] = true; qq[#qq + 1] = ns end end end end end
  return false
end
local fl = {}; for i in pairs(dead) do fl[i] = flipLive(i) end
local csize = {}; for i in pairs(dead) do csize[i] = #closure(i) end
local liveMarked = 0; for i = 1, n do if live[i] and def.visibleLoss and def.visibleLoss(lvl, sts[i]) then liveMarked = liveMarked + 1 end end
local authorMarks = 0; for i in pairs(dead) do if def.visibleLoss(lvl, sts[i]) then authorMarks = authorMarks + 1 end end
print(string.format("правило файла помечает: мёртвых %d, живых %d", authorMarks, liveMarked))
local function show(name, f) local hd, p = pct(f); print(string.format("  %-58s скрытых %3d = %5.1f %%", name, hd, p)) end
show("(а) как в файле", function(i) return def.visibleLoss(lvl, sts[i]) end)
show("(б) только общая линейка (для уровня без деталей — ничего)", function() return false end)
show("(в) «перевёрнутым тоже не выиграть» (мерка k9)", function(i) return not fl[i] end)
for _, k in ipairs({ 4, 8, 12, 16, 20, 30, 40, 60, 80, 100, 124, 152 }) do
  show("карман тела: всё будущее ≤ " .. k .. " сост.", function(i) return csize[i] <= k end)
end
local hc = {}; for i in pairs(dead) do hc[csize[i]] = (hc[csize[i]] or 0) + 1 end
local ks = {}; for k in pairs(hc) do ks[#ks + 1] = k end; table.sort(ks)
local t = {}; for _, k in ipairs(ks) do t[#t + 1] = k .. "×" .. hc[k] end
print("  размеры будущего у мёртвых (сост.×шт): " .. table.concat(t, " "))

-- классы мёртвых
local cls = {}
for i in pairs(dead) do local k = region(sts[i]) .. " | якорь [" .. anchorKey(sts[i]) .. "]"; cls[k] = (cls[k] or 0) + 1 end
local cl = {}; for k, v in pairs(cls) do cl[#cl + 1] = { k, v } end; table.sort(cl, function(a, b) return a[2] > b[2] end)
print("классы мёртвых (область | якорь):"); for _, c in ipairs(cl) do print(string.format("  %3d  %s", c[2], c[1])) end
local lcls = {}
for i = 1, n do if live[i] then local k = region(sts[i]); lcls[k] = (lcls[k] or 0) + 1 end end
local t2 = {}; for k, v in pairs(lcls) do t2[#t2 + 1] = k .. " " .. v end
print("живые по областям: " .. table.concat(t2, "; "))
-- самая высокая точка тела в мёртвом (минимальный y)
local topDead = 99; for i in pairs(dead) do for _, c in ipairs(sts[i].body) do local _, y = xy(c); if y < topDead then topDead = y end end end
print("самая высокая клетка тела во всех мёртвых: y=" .. topDead)
-- компоненты мёртвых (сильная связность через обратимость: неориентированно)
local comp, nc = {}, 0
for i in pairs(dead) do if not comp[i] then nc = nc + 1; local qq, hh = { i }, 1; comp[i] = nc
  while hh <= #qq do local u = qq[hh]; hh = hh + 1
    local nb = {}; for _, e in ipairs(succ[u]) do nb[#nb + 1] = e.j end; for _, v in ipairs(rev[u] or {}) do nb[#nb + 1] = v end
    for _, v in ipairs(nb) do if dead[v] and not comp[v] then comp[v] = nc; qq[#qq + 1] = v end end end end end
local csz = {}; for i in pairs(dead) do csz[comp[i]] = (csz[comp[i]] or 0) + 1 end
local t3 = {}; for c = 1, nc do t3[#t3 + 1] = csz[c] end
print("связных областей мёртвых: " .. nc .. " (размеры " .. table.concat(t3, ",") .. ")")
-- выход из мёртвых в живые невозможен по определению; есть ли обратимость внутри
local irrev = 0; for i in pairs(dead) do local _, seen = closure(i); local back = false
  for _, v in ipairs(rev[i] or {}) do if seen[v] then back = true end end; if not back then irrev = irrev + 1 end end
print("мёртвых, куда нельзя вернуться из своего будущего (односторонние): " .. irrev)

-- 3. двери с пути
print("ДВЕРИ (живое на пути → мёртвое):")
local function hiddenDepth(j) local qq, seen = closure(j, dead); local md = 0; for _, u in ipairs(qq) do if seen[u] > md then md = seen[u] end end; return md, #qq end
-- «потолок»: сколько ходов из входа до самой высокой точки, достижимой в кармане (там упираешься в «натянут»)
local function toCeiling(j)
  local qq, seen = closure(j, dead); local best, bd = 99, nil
  for _, u in ipairs(qq) do local my = 99; for _, c in ipairs(sts[u].body) do local _, y = xy(c); if y < my then my = y end end
    if my < best or (my == best and seen[u] < bd) then best, bd = my, seen[u] end end
  return best, bd
end
local doorSteps = {}
for k = 1, #path - 1 do
  local s = path[k]
  for _, e in ipairs(succ[s]) do if dead[e.j] then
    local dp, sz = hiddenDepth(e.j); local cy, cd = toCeiling(e.j)
    local hint = def.hintError and def.hintError(lvl, sts[s], sts[e.j]) or false
    print(string.format("  шаг %2d: %s, после — %s [%s]; глубина %d, карман %d; потолок y=%d через %d; ошибка подсказки=%s",
      k - 1, e.fall and "с падением" or "без падения", region(sts[e.j]), anchorKey(sts[e.j]), dp, sz, cy, cd, tostring(hint)))
    doorSteps[k - 1] = (doorSteps[k - 1] or 0) + 1
  end end
end
-- все входы (по всему графу) по типу
local dt = {}
local nd, ndh = 0, 0
for i = 1, n do if live[i] then for _, e in ipairs(succ[i]) do if dead[e.j] then nd = nd + 1
  local k = (e.fall and "падение → " or "шаг → ") .. region(sts[e.j]) .. " [" .. anchorKey(sts[e.j]) .. "]"
  dt[k] = (dt[k] or 0) + 1
  if def.hintError(lvl, sts[i], sts[e.j]) then ndh = ndh + 1 end end end end end
print("все входы живое→мёртвое: " .. nd .. " (из них ошибка подсказки: " .. ndh .. ")")
for k, v in pairs(dt) do print(string.format("  %3d  %s", v, k)) end
-- откуда (область живого) входят
local fromR = {}
for i = 1, n do if live[i] then for _, e in ipairs(succ[i]) do if dead[e.j] then local k = region(sts[i]); fromR[k] = (fromR[k] or 0) + 1 end end end end
local t4 = {}; for k, v in pairs(fromR) do t4[#t4 + 1] = k .. " " .. v end
print("входы из областей: " .. table.concat(t4, "; "))
-- ошибка подсказки по всему графу: из живого, куда ведёт
local hl, hd = 0, 0
for i = 1, n do if not sts[i].dead then for _, e in ipairs(succ[i]) do if def.hintError(lvl, sts[i], sts[e.j]) then
  if live[i] then if live[e.j] then hl = hl + 1 else hd = hd + 1 end end end end end end
print(string.format("ошибка подсказки из живых: в живое %d, в мёртвое %d", hl, hd))

-- 4. путь: события, выборы
local function ev(a, b, fall) return fall or anchorKey(sts[a]) ~= anchorKey(sts[b]) end
local walk, mw, fr, mf, evs = 0, 0, 0, 0, 0
local line = {}
for k = 1, #path - 1 do
  local s, t = path[k], path[k + 1]
  local alt, doors, back = 0, 0, 0
  for _, e in ipairs(succ[s]) do
    if live[e.j] and e.j ~= t then if k > 1 and e.j == path[k - 1] then back = back + 1 else alt = alt + 1 end end
    if dead[e.j] then doors = doors + 1 end
  end
  local isE = false; for _, e in ipairs(succ[s]) do if e.j == t then isE = ev(s, t, e.fall) end end
  if isE then evs = evs + 1; walk = 0 else walk = walk + 1; mw = math.max(mw, walk) end
  if alt + doors == 0 then fr = fr + 1; mf = math.max(mf, fr) else fr = 0 end
  line[#line + 1] = string.format("%d:%s%s a%d d%d %s", k - 1, isE and "*" or "", region(sts[s]):sub(1, 10), alt, doors, anchorKey(sts[s]))
end
print(string.format("путь %d: событий %d, прогулка max %d, вынужденных (нет ни живой альтернативы, ни двери) подряд max %d", opt, evs, mw, mf))
for _, l in ipairs(line) do print("  " .. l) end

-- 6. старт и обезьяна
local startMoves = #succ[1]
local sf = 0; for _, e in ipairs(succ[1]) do if e.fall then sf = sf + 1 end end
print(string.format("старт: ходов %d, из них с падением %d", startMoves, sf))
-- доля живых рёбер с падением по областям
local fr2 = {}
for i = 1, n do if live[i] then local r = region(sts[i]); fr2[r] = fr2[r] or { 0, 0 }
  for _, e in ipairs(succ[i]) do fr2[r][1] = fr2[r][1] + 1; if e.fall then fr2[r][2] = fr2[r][2] + 1 end end end end
for r, v in pairs(fr2) do print(string.format("  рёбер из живых «%s»: %d, с падением %d", r, v[1], v[2])) end
-- случайный игрок (все ходы равновероятны; смыва нет) — распределение по областям через T ходов
for _, T in ipairs({ 16, 80, 400, 1000 }) do
  local p, ok = { [1] = 1 }, 0
  local firstRidge = 0
  for _ = 1, T do local np = {}
    for i, pr in pairs(p) do local c = succ[i]
      if #c == 0 then np[i] = (np[i] or 0) + pr else for _, e in ipairs(c) do local sh = pr / #c
        if win[e.j] then ok = ok + sh else np[e.j] = (np[e.j] or 0) + sh end end end end
    p = np end
  local byR = {}
  for i, pr in pairs(p) do local r = region(sts[i]) .. (dead[i] and " (мёртв)" or ""); byR[r] = (byR[r] or 0) + pr end
  local tt = {}; for r, v in pairs(byR) do if v > 0.001 then tt[#tt + 1] = string.format("%s %.1f%%", r, 100 * v) end end
  print(string.format("случайный за %d ходов (одна попытка): выигрыш %.4f %%; %s", T, 100 * ok, table.concat(tt, "; ")))
end
-- расстояние от старта до первого выхода на гребень и до первой двери
local fr3; for i = 1, n do if region(sts[i]) == "гребень" and (not fr3 or dist[i] < fr3) then fr3 = dist[i] end end
print("до гребня минимум ходов: " .. tostring(fr3))
return { sts = sts, succ = succ, live = live, dead = dead, path = path }
