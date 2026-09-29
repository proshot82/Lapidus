-- build/l2v/probe.lua — слепая проверка кандидатов кв. 2 (скептик, 29.09). Печатает только метрики.
-- luajit build/l2v/probe.lua файл.lua [path]   (path — печатать по шагам кратчайшего пути числа, без ходов)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local file = arg[1]
local def = dofile(file)
local lvl = R.compile(def)
local W = lvl.W

local function ends(st)
  if st.dead then return "X" end
  local piece = R.occupancy(st)
  local h = R.endScrew(lvl, st, piece, "head")
  local f = R.endScrew(lvl, st, piece, "heel")
  return (h and ("H" .. h) or "") .. "|" .. (f and ("F" .. f) or "")
end

-- граф
local function build(L, filter)
  local s0 = R.newState(L)
  local idx, sts, succ, win, dead, fall, par, dist = {}, {}, {}, {}, {}, {}, {}, {}
  local function add(s) local k = R.key(s); local i = idx[k]; if not i then i = #sts + 1; idx[k] = i; sts[i] = s end; return i end
  add(s0); dist[1] = 0
  local h = 1
  while h <= #sts do
    local s = sts[h]
    dead[h] = s.dead
    win[h] = (not s.dead) and R.isWin(L, s)
    local out = {}
    if not dead[h] and not win[h] then
      for m = 1, 8 do
        local tr = {}
        local ns = R.move(L, s, R.MOVES[m].which, R.MOVES[m].dir, tr)
        if ns and (not filter or filter(L, s, ns)) then
          local j = add(ns)
          if not dist[j] then dist[j] = dist[h] + 1; par[j] = h end
          -- падение: тело сдвинулось после самого хода
          local moved = false
          local b0 = tr[1].state.body
          if ns.dead then moved = true else
            for k = 1, #b0 do if b0[k] ~= ns.body[k] then moved = true break end end
          end
          out[#out + 1] = { j = j, m = m, fall = moved }
        end
      end
    end
    succ[h] = out
    h = h + 1
  end
  local rev = {}
  for i = 1, #sts do for _, e in ipairs(succ[i]) do rev[e.j] = rev[e.j] or {}; table.insert(rev[e.j], i) end end
  local live, q = {}, {}
  for i = 1, #sts do if win[i] then live[i] = true; q[#q + 1] = i end end
  local qh = 1
  while qh <= #q do local j = q[qh]; qh = qh + 1; for _, i in ipairs(rev[j] or {}) do if not live[i] then live[i] = true; q[#q + 1] = i end end end
  return { sts = sts, idx = idx, succ = succ, win = win, dead = dead, live = live, par = par, dist = dist }
end

local function solvable(d, filter)
  local ok, L = pcall(R.compile, d)
  if not ok then return false end
  local e = R.validate(L); if #e > 0 then return false end
  local G = build(L, filter)
  local best
  for i = 1, #G.sts do if G.win[i] and (not best or G.dist[i] < best) then best = G.dist[i] end end
  return best ~= nil, best, G
end

local G = build(lvl)
local n = #G.sts
local opt
for i = 1, n do if G.win[i] and (not opt or G.dist[i] < opt) then opt = G.dist[i] end end
local nwin = 0; for i = 1, n do if G.win[i] then nwin = nwin + 1 end end
print(string.format("%s: состояний %d, кратчайшее %s, выигрышных состояний %d", file, n, tostring(opt), nwin))

-- перевёрнутый двойник: живой ли (строим его собственное замыкание)
local function flip(st)
  local s = R.clone(st); local b, m = s.body, #s.body
  for i = 1, math.floor(m / 2) do b[i], b[m + 1 - i] = b[m + 1 - i], b[i] end
  R.settle(lvl, s); return s
end
local flipLiveCache = {}
local function flipLive(i)
  if flipLiveCache[i] ~= nil then return flipLiveCache[i] end
  local fs = flip(G.sts[i])
  local j = G.idx[R.key(fs)]
  local res
  if j then res = G.live[j] and true or false else
    -- двойник вне графа: отдельный поиск вперёд до выигрыша
    local seen, q, h = { [R.key(fs)] = true }, { fs }, 1
    res = false
    while h <= #q and #q < 20000 do
      local s = q[h]; h = h + 1
      if not s.dead then
        if R.isWin(lvl, s) then res = true break end
        for m = 1, 8 do local ns = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir)
          if ns then local k = R.key(ns); if not seen[k] then seen[k] = true; q[#q + 1] = ns end end end
      end
    end
  end
  flipLiveCache[i] = res; return res
end

-- замыкание вперёд
local function closure(i)
  local seen, q, h = { [i] = true }, { i }, 1
  while h <= #q do local u = q[h]; h = h + 1; for _, e in ipairs(G.succ[u]) do if not seen[e.j] then seen[e.j] = true; q[#q + 1] = e.j end end end
  return q
end

-- мерки
local deadNW = {}  -- мёртвые, Лапидус не смыт
local nlive, nwash = 0, 0
for i = 1, n do
  if G.dead[i] then nwash = nwash + 1 elseif G.live[i] then nlive = nlive + 1 else deadNW[#deadNW + 1] = i end
end
local measures = {}
local function pct(vis)
  local hid = 0; for _, i in ipairs(deadNW) do if not vis(i) then hid = hid + 1 end end
  return hid, 100 * hid / math.max(1, hid + nlive)
end
local defVL = def.visibleLoss
local function mAuthor(i) return defVL and defVL(lvl, G.sts[i]) or false end
local function mFlip(i) return not flipLive(i) end
local neverGrab = {}
for _, i in ipairs(deadNW) do
  local any = false
  for _, u in ipairs(closure(i)) do if not G.dead[u] and ends(G.sts[u]) ~= "|" then any = true break end end
  neverGrab[i] = not any
end
local function mNever(i) return neverGrab[i] end
local csize = {}
for _, i in ipairs(deadNW) do local c = 0; for _, u in ipairs(closure(i)) do if not G.dead[u] then c = c + 1 end end; csize[i] = c end
print(string.format("живых %d, мёртвых (не смыт) %d, смыт %d", nlive, #deadNW, nwash))
local function show(name, f) local h, p = pct(f); print(string.format("  мерка %-44s скрытых %3d = %5.1f %%", name, h, p)) end
show("нет (всё мёртвое скрыто)", function() return false end)
show("автора (def.visibleLoss)", mAuthor)
show("перевёрнутым тоже не выиграть (как k9)", mFlip)
show("никогда больше не прикрутится", mNever)
show("перевёрнутым нельзя ИЛИ не прикрутится", function(i) return mFlip(i) or mNever(i) end)
for k = 2, 12, 2 do
  show("перевёрн. ИЛИ «карман» будущего ≤ " .. k .. " сост.", function(i) return mFlip(i) or csize[i] <= k end)
end
-- честность мерки автора: помечает ли живые; совпадает ли с моей реализацией
local liveMarked, mism = 0, 0
for i = 1, n do if not G.dead[i] then
  if G.live[i] and mAuthor(i) then liveMarked = liveMarked + 1 end
  if not G.live[i] and defVL and (mAuthor(i) ~= mFlip(i)) then mism = mism + 1 end
end end
print(string.format("  мерка автора помечает живых: %d; расхождений с моей перевёрнутой меркой: %s", liveMarked, defVL and mism or "—"))

-- скрытые (по мерке «перевёрнутым нельзя») — классы
local hidden = {}
for _, i in ipairs(deadNW) do if not mFlip(i) then hidden[i] = true end end
local cls = {}
for i in pairs(hidden) do
  local s = G.sts[i]; local e = ends(s)
  local k = (e == "|" and "ни один конец не прикручен" or "висит на крюке") .. (neverGrab[i] and ", больше не прикрутится" or ", ещё прикручивается")
  cls[k] = (cls[k] or 0) + 1
end
for k, v in pairs(cls) do print(string.format("  класс скрытых: %-50s %d", k, v)) end

-- входы в мёртвое из живого
local entries = {}
for i = 1, n do if G.live[i] then for _, e in ipairs(G.succ[i]) do local j = e.j
  if not G.dead[j] and not G.live[j] then entries[#entries + 1] = { i = i, j = j, fall = e.fall, m = e.m } end end end end
local function hiddenDepth(j)
  if not hidden[j] then return -1, 0 end
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for _, e in ipairs(G.succ[u]) do local v = e.j; if hidden[v] and not d[v] then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end end end
  return maxd, #q
end
print(string.format("входов живое→мёртвое (не смыт): %d", #entries))
local eg = {}
for _, en in ipairs(entries) do
  local dp, sz = hiddenDepth(en.j)
  local k = string.format("%s, %s, глубина %d, область %d", en.fall and "с падением" or "без падения",
    hidden[en.j] and "СКРЫТО" or "видимо", dp, sz)
  eg[k] = (eg[k] or 0) + 1
end
for k, v in pairs(eg) do print("  вход: " .. k .. "  ×" .. v) end
local ew = 0; for i = 1, n do if G.live[i] then for _, e in ipairs(G.succ[i]) do if G.dead[e.j] then ew = ew + 1 end end end end
print("  ходов живое→смыт: " .. ew)

-- кратчайший путь: выбор и события
local goal; for i = 1, n do if G.win[i] and G.dist[i] == opt then goal = i end end
local path = {}; local x = goal; while x do table.insert(path, 1, x); x = G.par[x] end
local ev, walk, maxWalk, forcedRun, maxForced, choices, tempt = 0, 0, 0, 0, 0, 0, 0
local line = {}
for k = 1, #path - 1 do
  local s, t = path[k], path[k + 1]
  local liveNU, hid = 0, 0
  for _, e in ipairs(G.succ[s]) do
    if G.live[e.j] and e.j ~= path[k - 1 > 0 and k - 1 or 0] and e.j ~= s then liveNU = liveNU + 1 end
    if hidden[e.j] then hid = hid + 1 end
  end
  if hid > 0 then tempt = tempt + 1 end
  if liveNU >= 2 then choices = choices + 1; forcedRun = 0 else forcedRun = forcedRun + 1; if forcedRun > maxForced then maxForced = forcedRun end end
  local isEv = false
  for _, e in ipairs(G.succ[s]) do if e.j == t then
    isEv = e.fall or ends(G.sts[s]) ~= ends(G.sts[t]) end end
  if isEv then ev = ev + 1; walk = 0 else walk = walk + 1; if walk > maxWalk then maxWalk = walk end end
  line[#line + 1] = (isEv and "*" or ".") .. liveNU .. (hid > 0 and "!" or "")
end
print(string.format("путь %d ходов: событий (прикрут/открут/падение) %d, прогулка max %d; развилок (≥2 живых не-откат) %d, вынужденных подряд max %d; шагов с соблазном в скрытый тупик %d",
  #path - 1, ev, maxWalk, choices, maxForced, tempt))
if arg[2] == "path" then print("  по шагам [*событие, число живых не-откат, !соблазн]: " .. table.concat(line, " ")) end

-- ошибка подсказки: «спуск ногами вперёд» (для k9/k11 — выход из комнаты старта ногами ниже головы)
if def.ablations then
  for _, a in ipairs(def.ablations) do if a.filter and a.name:find("головой") then
    local cnt, lv, dp, sz = 0, 0, 0, 0
    for i = 1, n do if G.live[i] then for _, e in ipairs(G.succ[i]) do
      if not a.filter(lvl, G.sts[i], G.sts[e.j]) then
        cnt = cnt + 1
        if G.live[e.j] then lv = lv + 1 else local d0, s0 = hiddenDepth(e.j); if d0 > dp then dp = d0 end; if s0 > sz then sz = s0 end
          print(string.format("  ошибка подсказки: вход %s, глубина скрытой ветки %d, её размер %d, на пути шаг %s",
            hidden[e.j] and "СКРЫТЫЙ" or (G.dead[e.j] and "смыт" or "видимый"), d0, s0, tostring(G.dist[i]))) end
      end end end end
    print(string.format("  ошибка подсказки (ноги вперёд из комнаты): переходов из живого %d, из них в живое %d", cnt, lv))
  end end
end
return { G = G, build = build, solvable = solvable, lvl = lvl, opt = opt }
