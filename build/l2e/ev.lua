-- build/l2e/ev.lua — оценка кандидата кв. 2 без деталей: все мерки скрытого разом (по образцу build/l2v/probe.lua).
-- luajit build/l2e/ev.lua файл.lua [path|frames]
-- файл возвращает def (полный формат) или { rows = {...}, opts = {...} } для build/l2e/mk.lua.
-- Печатает только метрики; кадры (frames) — только в терминал.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local ST = require("solver.strict")
local MK = dofile("build/l2e/mk.lua")
local M = {}

local function ends(lvl, st)
  if st.dead then return "X" end
  local piece = R.occupancy(st)
  local h = R.endScrew(lvl, st, piece, "head")
  local f = R.endScrew(lvl, st, piece, "heel")
  return (h and ("H" .. h) or "") .. "|" .. (f and ("F" .. f) or "")
end

local function build(L, filter)
  local s0 = R.newState(L)
  local idx, sts, succ, win, dead, par, dist = {}, {}, {}, {}, {}, {}, {}
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
  return { sts = sts, idx = idx, succ = succ, win = win, dead = dead, live = live, par = par, dist = dist, rev = rev }
end
M.build = build

function M.load(file)
  local d = dofile(file)
  if d.rows then d = MK.build(d.rows, d.opts) end
  return d
end

function M.eval(def, opt2, quiet, fast)
  local out = {}
  local function P(...) if not quiet then print(...) end end
  local ok, lvl = pcall(R.compile, def)
  if not ok then P("COMPILE: " .. tostring(lvl)); return { fail = "compile" } end
  local errs = R.validate(lvl)
  if #errs > 0 then P("ОШИБКИ: " .. table.concat(errs, "; ")); return { fail = "invalid" } end
  local G = build(lvl)
  local n = #G.sts
  local opt
  for i = 1, n do if G.win[i] and (not opt or G.dist[i] < opt) then opt = G.dist[i] end end
  if not opt then P(string.format("НЕРЕШАЕМ (состояний %d)", n)); return { fail = "unsolvable", n = n } end
  local nwin = 0; for i = 1, n do if G.win[i] then nwin = nwin + 1 end end
  -- выигрышные конфигурации: тело в момент победы
  local wcfg = {}
  for i = 1, n do if G.win[i] then wcfg[table.concat(G.sts[i].body, ",")] = true end end
  local nwcfg = 0; for _ in pairs(wcfg) do nwcfg = nwcfg + 1 end
  out.opt, out.n, out.nwin, out.nwcfg = opt, n, nwin, nwcfg

  local function flip(st)
    local s = R.clone(st); local b, m = s.body, #s.body
    for i = 1, math.floor(m / 2) do b[i], b[m + 1 - i] = b[m + 1 - i], b[i] end
    R.settle(lvl, s); return s
  end
  local flipCache = {}
  local function flipLive(i)
    if flipCache[i] ~= nil then return flipCache[i] end
    local fs = flip(G.sts[i]); local j = G.idx[R.key(fs)]
    local res
    if j then res = G.live[j] and true or false else
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
    flipCache[i] = res; return res
  end
  local function closure(i)
    local seen, q, h = { [i] = true }, { i }, 1
    while h <= #q do local u = q[h]; h = h + 1; for _, e in ipairs(G.succ[u]) do if not seen[e.j] then seen[e.j] = true; q[#q + 1] = e.j end end end
    return q
  end
  local deadNW, nlive, nwash = {}, 0, 0
  for i = 1, n do
    if G.dead[i] then nwash = nwash + 1 elseif G.live[i] then nlive = nlive + 1 else deadNW[#deadNW + 1] = i end
  end
  out.live, out.washed, out.deadNW = nlive, nwash, #deadNW
  local defVL = def.visibleLoss
  local function mAuthor(i) return defVL and defVL(lvl, G.sts[i]) or false end
  local function mFlip(i) return not flipLive(i) end
  local neverGrab, csize = {}, {}
  for _, i in ipairs(deadNW) do
    local any, c = false, 0
    for _, u in ipairs(closure(i)) do if not G.dead[u] then c = c + 1; if ends(lvl, G.sts[u]) ~= "|" then any = true end end end
    neverGrab[i] = not any; csize[i] = c
  end
  local function pct(vis)
    local hid = 0; for _, i in ipairs(deadNW) do if not vis(i) then hid = hid + 1 end end
    return hid, 100 * hid / math.max(1, hid + nlive)
  end
  P(string.format("ходов %d | состояний %d (живых %d, мёртвых не смыт %d, смыт %d) | выигрышных %d, конфигураций %d",
    opt, n, nlive, #deadNW, nwash, nwin, nwcfg))
  local function show(name, f) local h, p = pct(f); P(string.format("  мерка %-46s скрытых %3d = %5.1f %%", name, h, p)); return p end
  out.pctNone = show("нет (всё мёртвое скрыто)", function() return false end)
  out.pctAuthor = show("автора (def.visibleLoss)", mAuthor)
  out.pctFlip = show("перевёрнутым тоже не выиграть", mFlip)
  out.pctNever = show("никогда больше не прикрутится", function(i) return neverGrab[i] end)
  out.pctBoth = show("перевёрнутым нельзя ИЛИ не прикрутится", function(i) return mFlip(i) or neverGrab[i] end)
  for _, k in ipairs({ 4, 8, 12, 20 }) do
    out["pctPocket" .. k] = show("не прикрутится ИЛИ «карман» ≤ " .. k .. " сост.", function(i) return neverGrab[i] or csize[i] <= k end)
  end
  local liveMarked = 0
  for i = 1, n do if G.live[i] and mAuthor(i) then liveMarked = liveMarked + 1 end end
  out.liveMarked = liveMarked
  P("  мерка автора помечает живых: " .. liveMarked)

  -- скрытые по мерке автора: классы
  local hidden = {}
  for _, i in ipairs(deadNW) do if not mAuthor(i) then hidden[i] = true end end
  local cls = {}
  for i in pairs(hidden) do
    local s = G.sts[i]; local e = ends(lvl, s)
    local k = (e == "|" and "конец не прикручен" or "висит") .. (flipLive(i) and ", перевёрнутым можно" or ", перевёрнутым нельзя")
    cls[k] = (cls[k] or 0) + 1
  end
  local cl = {}
  for k, v in pairs(cls) do cl[#cl + 1] = string.format("%s %d", k, v) end
  table.sort(cl)
  P("  классы скрытых: " .. table.concat(cl, "; "))
  out.classes = cl

  -- умная обезьяна (мерка автора), как в check.lua
  local T = 5 * opt
  local p, okp = { [1] = 1.0 }, 0
  local visA = {}
  for i = 1, n do if not G.dead[i] and not G.live[i] then visA[i] = mAuthor(i) end end
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for _, e in ipairs(G.succ[i]) do local j = e.j
        if G.win[j] then cand[#cand + 1] = j elseif not G.dead[j] and not visA[j] then cand[#cand + 1] = j end end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.win[j] then okp = okp + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  out.smart = 100 * (1 - (1 - okp) ^ (1000 / T))
  local liveP = 0; for i, pr in pairs(p) do if G.live[i] then liveP = liveP + pr end end
  out.smartLive = 100 * liveP

  -- кратчайший путь
  local goal; for i = 1, n do if G.win[i] and G.dist[i] == opt then goal = i end end
  local path = {}; local x = goal; while x do table.insert(path, 1, x); x = G.par[x] end
  local function hiddenDepth(j)
    if not hidden[j] then return -1, 0 end
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do local u = q[h]; h = h + 1
      for _, e in ipairs(G.succ[u]) do local v = e.j; if hidden[v] and not d[v] then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end end end
    return maxd, #q
  end
  local deepAt, maxDeep = {}, 0
  for k = 1, #path - 1 do
    for _, e in ipairs(G.succ[path[k]]) do
      if hidden[e.j] then local d = hiddenDepth(e.j); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
  out.deep, out.deepList = maxDeep, table.concat(dl, " ")
  -- двери (ворота 30.09): шаги пути с рёбрами в скрытое, по половинам
  local halves = { 0, 0 }
  for k = 1, #path - 1 do
    local c = 0
    for _, e in ipairs(G.succ[path[k]]) do if hidden[e.j] then c = c + 1 end end
    if c > 0 then local hidx = ((k - 1) < (#path - 1) / 2) and 1 or 2; halves[hidx] = halves[hidx] + 1 end
  end
  out.doors1, out.doors2 = halves[1], halves[2]
  local ev, walk, maxWalk, forcedRun, maxForced, choices, tempt = 0, 0, 0, 0, 0, 0, 0
  local line = {}
  local pathFalls, fallSteps = 0, {}
  for k = 1, #path - 1 do
    local s, t = path[k], path[k + 1]
    local liveNU, hid = 0, 0
    for _, e in ipairs(G.succ[s]) do
      if G.live[e.j] and e.j ~= (path[k - 1] or 0) and e.j ~= s then liveNU = liveNU + 1 end
      if hidden[e.j] then hid = hid + 1 end
    end
    if hid > 0 then tempt = tempt + 1 end
    if liveNU >= 2 then choices = choices + 1; forcedRun = 0 else forcedRun = forcedRun + 1; if forcedRun > maxForced then maxForced = forcedRun end end
    local isEv = false
    for _, e in ipairs(G.succ[s]) do if e.j == t then isEv = e.fall or ends(lvl, G.sts[s]) ~= ends(lvl, G.sts[t]); if e.fall then pathFalls = pathFalls + 1; fallSteps[#fallSteps + 1] = k - 1 end end end
    if isEv then ev = ev + 1; walk = 0 else walk = walk + 1; if walk > maxWalk then maxWalk = walk end end
    line[#line + 1] = (isEv and "*" or ".") .. liveNU .. (hid > 0 and "!" or "")
  end
  out.events, out.walk, out.choices, out.forced, out.tempt = ev, maxWalk, choices, maxForced, tempt
  out.pathFalls, out.fallSteps = pathFalls, table.concat(fallSteps, ",")
  -- входы живое→скрытое
  local eg, nEntries = {}, 0
  for i = 1, n do if G.live[i] then for _, e in ipairs(G.succ[i]) do local j = e.j
    if not G.dead[j] and not G.live[j] then nEntries = nEntries + 1
      local dp, sz = hiddenDepth(j)
      local k = string.format("%s, %s, глубина %d, область %d, с шага %d", e.fall and "с падением" or "без падения",
        hidden[j] and "СКРЫТО" or "видимо", dp, sz, G.dist[i])
      eg[k] = (eg[k] or 0) + 1 end end end end
  local sx = (not fast) and ST.check(def, 3000000) or nil
  out.monkey, out.shortest, out.width = sx and sx.monkey or -1, sx and sx.shortest or -1, sx and sx.maxWidth or -1
  P(string.format("СКРЫТЫХ (автор) %.1f %% | умная обезьяна %.2f %% (ещё живы %.0f %%) | наобум %.3f %% | кратчайших %d, ширина %d | глубина скрытой ветки у пути %d [%s]",
    out.pctAuthor, out.smart, out.smartLive, out.monkey, out.shortest, out.width, maxDeep, out.deepList))
  P(string.format("путь %d: событий %d, прогулка max %d, развилок %d, вынужденных подряд max %d, шагов с соблазном %d (двери: %d в 1-й половине, %d во 2-й), падений на пути %d (шаги %s)",
    #path - 1, ev, maxWalk, choices, maxForced, tempt, out.doors1, out.doors2, pathFalls, out.fallSteps))
  if opt2 == "path" then P("  по шагам [*событие, живых не-откат, !соблазн]: " .. table.concat(line, " ")) end
  local egl = {}
  for k, v in pairs(eg) do egl[#egl + 1] = "  вход: " .. k .. "  ×" .. v end
  table.sort(egl)
  for _, s in ipairs(egl) do P(s) end
  out.entries = nEntries
  -- ошибка подсказки: def.hintError(lvl, st, ns) → true, если ход — «ошибка подсказки №1»
  if def.hintError then
    local cnt, lv, dp, hidN, visN = 0, 0, 0, 0, 0
    local seenJ = {}
    for i = 1, n do if G.live[i] then for _, e in ipairs(G.succ[i]) do
      if def.hintError(lvl, G.sts[i], G.sts[e.j]) then
        cnt = cnt + 1
        if G.live[e.j] then lv = lv + 1 elseif G.dead[e.j] then visN = visN + 1
        elseif hidden[e.j] then hidN = hidN + 1; if not seenJ[e.j] then seenJ[e.j] = true; local d0 = hiddenDepth(e.j); if d0 > dp then dp = d0 end end
        else visN = visN + 1 end
      end end end end
    out.hintTotal, out.hintLive, out.hintHidden, out.hintVisible, out.hintDepth = cnt, lv, hidN, visN, dp
    P(string.format("ошибка подсказки №1: переходов из живого %d — в живое %d, в СКРЫТЫЙ тупик %d (глубина до %d), в видимый/смыт %d", cnt, lv, hidN, dp, visN))
  end
  if opt2 == "frames" then
    local SYM = { source = "S", fixture = "F", stub = "T" }
    local function show(s, label)
      local rows = {}
      for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y - 1) * lvl.W + x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
      for q, pp in ipairs(lvl.pieces) do local x, y = R.xy(lvl, pp.start); local ch = SYM[pp.kind]
        if pp.kind == "stub" then local th; for _, t in pairs(pp.ports) do th = t end; ch = th == "N" and "N" or "v" end
        rows[y][x] = ch end
      if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
      local o = { label }
      for y = 1, lvl.H do o[#o + 1] = table.concat(rows[y]) end
      return o
    end
    local frames = {}
    for i, id in ipairs(path) do
      local st = G.sts[id]
      local lab = (i == 1) and "start" or tostring(i - 1)
      for _, e in ipairs(G.succ[path[i - 1] or 0] or {}) do if e.j == id then lab = lab .. R.moveName(e.m):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3) end end
      frames[#frames + 1] = show(st, lab)
    end
    local per = math.max(1, math.floor(120 / (lvl.W + 2)))
    for k = 1, #frames, per do
      for l = 1, #frames[k] do
        local parts = {}
        for j = k, math.min(k + per - 1, #frames) do parts[#parts + 1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][l] or "") end
        print(table.concat(parts, ""))
      end
      print()
    end
  end
  out.G, out.lvl, out.hidden, out.path = G, lvl, hidden, path
  return out
end

local a1, a2 = ...
if a1 then M.eval(M.load(a1), a2) end
return M
