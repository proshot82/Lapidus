-- build/l1c/envelope.lua — «огибающая» для доказательства цифрами (не для постройки уровня!):
-- какие доли скрытых тупиков и какую умную обезьяну вообще дают уровни БЕЗ подвижных деталей
-- (стены, сливы, стояк, ванна, один глухой отвод) на поле W×H при длине Lmin–Lmax, если крюк обязателен.
-- luajit build/l1c/envelope.lua <секунд> <seed> <W> <H> <Lmax> <файл-вывода> [pitRow=1|any]
-- Мерка видимого проигрыша — мерка новичка build/l1c (класс P: нельзя выиграть ни так, ни перевёрнутым концами).
-- Пишет лучшие (фронт Парето по скрытым ↑ и обезьяне ↓) в файл; решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local secs = tonumber(arg[1] or 60)
local seed = tonumber(arg[2] or 1)
local W, H = tonumber(arg[3] or 10), tonumber(arg[4] or 7)
local LMAX = tonumber(arg[5] or 4)
local out = arg[6] or "build/l1c/envelope.txt"
local anyPit = (arg[7] == "any")
math.randomseed(seed)

local DIRS = { "up", "right", "down", "left" }
local DX, DY = { 0, 1, 0, -1 }, { -1, 0, 1, 0 }

local function noHook(lvl, st, ns)
  local piece = R.occupancy(ns)
  for _, which in ipairs({ "head", "heel" }) do
    local q = R.endScrew(lvl, ns, piece, which)
    if q and lvl.pieces[q].kind == "stub" then return false end
  end
  return true
end

local function flipState(lvl, st)
  local s = R.clone(st)
  local b, n = s.body, #s.body
  for i = 1, math.floor(n / 2) do b[i], b[n + 1 - i] = b[n + 1 - i], b[i] end
  R.settle(lvl, s)
  return s
end

local function evaluate(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil, "compile" end
  local errs = R.validate(lvl)
  if #errs > 0 then return nil, "validate" end
  local G = SV.explore(lvl, 6000)
  if not G then return nil, "cap" end
  if not G.firstWin then SV.freeGraph(G) return nil, "unsolvable" end
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local opt = G.depth[G.firstWin]
  if nwin ~= 1 then SV.freeGraph(G) return nil, "multiwin" end
  if opt < 6 then SV.freeGraph(G) return nil, "short" end
  local G2 = SV.explore(lvl, 6000, noHook)
  local hookNeeded = G2 and not G2.firstWin
  SV.freeGraph(G2)
  if not hookNeeded then SV.freeGraph(G) return nil, "nohook" end
  local good = SV.goodSet(G)
  -- замыкание с переворотами
  local idx2, keys2, succ2, win2 = {}, {}, {}, {}
  local function add2(k) local i = idx2[k]; if not i then i = #keys2 + 1; keys2[i] = k; idx2[k] = i end; return i end
  add2(R.key(R.newState(lvl)))
  local h = 1
  while h <= #keys2 do
    if #keys2 > 30000 then SV.freeGraph(G); require("ffi").C.free(good) return nil end
    local st = R.decode(lvl, keys2[h])
    local o = {}
    if not st.dead then
      if R.isWin(lvl, st) then win2[h] = true else
        for m = 1, 8 do
          local ns = R.move(lvl, st, R.MOVES[m].which, R.MOVES[m].dir)
          if ns then o[#o + 1] = add2(R.key(ns)) end
        end
      end
      add2(R.key(flipState(lvl, st)))
    end
    succ2[h] = o
    h = h + 1
  end
  local rev = {}
  for i = 1, #keys2 do for _, j in ipairs(succ2[i]) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end
  local ok2, q, qh = {}, {}, 1
  for i in pairs(win2) do ok2[i] = true; q[#q + 1] = i end
  while qh <= #q do local j = q[qh]; qh = qh + 1; for _, i in ipairs(rev[j] or {}) do if not ok2[i] then ok2[i] = true; q[#q + 1] = i end end end
  local vis = {}
  local live, hid, nvis = 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1 else
        local st = R.decode(lvl, G.keys[i])
        local fi = idx2[R.key(flipState(lvl, st))]
        if fi and ok2[fi] then hid = hid + 1; hidden[i] = true else vis[i] = true; nvis = nvis + 1 end
      end
    end
  end
  -- умная обезьяна
  local T = 5 * opt
  local p, okp = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not vis[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then okp = okp + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - okp) ^ (1000 / T))
  -- глубина скрытой ветки у кратчайшего пути
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local maxDeep = 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then
        local d, qq, hh = { [j] = 0 }, { j }, 1
        while hh <= #qq do
          local u = qq[hh]; hh = hh + 1
          for e2 = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
            local v = G.edges.p[e2]
            if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxDeep then maxDeep = d[v] end; qq[#qq + 1] = v end
          end
        end
      end
    end
  end
  local res = { opt = opt, n = G.n, live = live, hid = hid, vis = nvis, pct = 100 * hid / math.max(1, hid + live), smart = smart, deep = maxDeep }
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end

-- случайная раскладка
local function randomDef()
  local g = {}
  for y = 1, H do
    g[y] = {}
    for x = 1, W do
      if x == 1 or x == W or y == 1 then g[y][x] = "#"
      elseif y == H then g[y][x] = (math.random() < 0.45) and "~" or "#"
      else
        local r = math.random()
        if anyPit and r < 0.06 then g[y][x] = "~" elseif r < 0.34 then g[y][x] = "#" else g[y][x] = "." end
      end
    end
  end
  return g
end

local function emptyCells(g, occ)
  local t = {}
  for y = 2, H - 1 do for x = 2, W - 1 do if g[y][x] == "." and not occ[y * 100 + x] then t[#t + 1] = { x, y } end end end
  return t
end

local function placeObj(g, occ, kind, thread)
  local cells = emptyCells(g, occ)
  for _ = 1, 40 do
    if #cells == 0 then return nil end
    local c = cells[math.random(#cells)]
    local dirs = {}
    for d = 1, 4 do
      local nx, ny = c[1] + DX[d], c[2] + DY[d]
      if g[ny] and g[ny][nx] == "." and not occ[ny * 100 + nx] then dirs[#dirs + 1] = d end
    end
    if #dirs > 0 then
      local d = dirs[math.random(#dirs)]
      occ[c[2] * 100 + c[1]] = true
      return { x = c[1], y = c[2], side = DIRS[d], th = thread }
    end
  end
  return nil
end

local function placeLap(g, occ)
  for _ = 1, 60 do
    local cells = emptyCells(g, occ)
    if #cells == 0 then return nil end
    local c = cells[math.random(#cells)]
    local L = math.random(2, LMAX)
    local body, used = { c }, { [c[2] * 100 + c[1]] = true }
    for _ = 2, L do
      local last = body[#body]
      local opts = {}
      for d = 1, 4 do
        local nx, ny = last[1] + DX[d], last[2] + DY[d]
        if g[ny] and g[ny][nx] == "." and not occ[ny * 100 + nx] and not used[ny * 100 + nx] then opts[#opts + 1] = { nx, ny } end
      end
      if #opts == 0 then break end
      local n = opts[math.random(#opts)]
      body[#body + 1] = n; used[n[2] * 100 + n[1]] = true
    end
    if #body >= 2 then return body end
  end
  return nil
end

local function toDef(L)
  local rows = {}
  for y = 1, H do rows[y] = table.concat(L.g[y]) end
  local objs = {
    { kind = "source", at = { L.src.x, L.src.y }, ports = { [L.src.side] = L.src.th } },
    { kind = "fixture", what = "bath", at = { L.fix.x, L.fix.y }, ports = { [L.fix.side] = L.fix.th } },
    { kind = "stub", tag = "hook", at = { L.hook.x, L.hook.y }, ports = { [L.hook.side] = L.hook.th } },
  }
  local cells = {}
  for i, c in ipairs(L.lap) do cells[i] = { c[1], c[2] } end
  objs[#objs + 1] = { kind = "lapidus", cells = cells, head = #cells }
  return { id = 1, name = "env", length = { 2, LMAX }, pressure = 0, grid = rows, objects = objs }
end

local function randomLayout()
  local g = randomDef()
  local occ = {}
  local sN = math.random() < 0.7
  local src = placeObj(g, occ, "source", sN and "N" or "V")
  local fix = placeObj(g, occ, "fixture", sN and "V" or "N")
  local hook = placeObj(g, occ, "stub", math.random() < 0.5 and "N" or "V")
  if not (src and fix and hook) then return nil end
  local lap = placeLap(g, occ)
  if not lap then return nil end
  return { g = g, src = src, fix = fix, hook = hook, lap = lap }
end

local function copyL(L)
  local g = {}
  for y = 1, H do g[y] = {}; for x = 1, W do g[y][x] = L.g[y][x] end end
  local function cp(o) return { x = o.x, y = o.y, side = o.side, th = o.th } end
  local lap = {}
  for i, c in ipairs(L.lap) do lap[i] = { c[1], c[2] } end
  return { g = g, src = cp(L.src), fix = cp(L.fix), hook = cp(L.hook), lap = lap }
end

local function mutate(L)
  local M = copyL(L)
  local k = math.random(6)
  if k <= 3 then
    for _ = 1, math.random(1, 3) do
      local x, y = math.random(2, W - 1), math.random(2, H)
      if y == H then M.g[y][x] = (M.g[y][x] == "#") and "~" or "#"
      else
        local cur = M.g[y][x]
        M.g[y][x] = (cur == "#") and "." or "#"
      end
    end
  elseif k == 4 then
    local which = ({ "src", "fix", "hook" })[math.random(3)]
    local o = M[which]
    if math.random() < 0.5 then o.side = DIRS[math.random(4)]
    else o.x = math.max(2, math.min(W - 1, o.x + math.random(-1, 1))); o.y = math.max(2, math.min(H - 1, o.y + math.random(-1, 1))) end
    if which == "hook" and math.random() < 0.3 then o.th = (o.th == "N") and "V" or "N" end
  else
    local occ = {}
    for _, o in ipairs({ M.src, M.fix, M.hook }) do occ[o.y * 100 + o.x] = true end
    local lap = placeLap(M.g, occ)
    if lap then M.lap = lap end
  end
  -- объекты и Лапидус должны стоять на пустых клетках
  for _, o in ipairs({ M.src, M.fix, M.hook }) do M.g[o.y][o.x] = "." end
  for _, c in ipairs(M.lap) do M.g[c[2]][c[1]] = "." end
  return M
end

local function score(r)
  -- чем больше скрытых и глубина, чем меньше обезьяна, тем лучше
  local w = tonumber(os.getenv("WMONK") or 8)
  return math.min(r.pct, 50) - w * math.log10(math.max(0.001, r.smart)) + 0.5 * math.min(r.deep, 12) + 0.3 * math.min(r.opt, 25)
end

local pool, best = {}, {}
local function fromDef(def)
  local g = {}
  for y = 1, H do g[y] = {}; for x = 1, W do g[y][x] = def.grid[y]:sub(x, x) end end
  local L = { g = g }
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then
      local cells = {}
      if o.head == #o.cells then for i, c in ipairs(o.cells) do cells[i] = { c[1], c[2] } end
      else for i = #o.cells, 1, -1 do cells[#cells + 1] = { o.cells[i][1], o.cells[i][2] } end end
      L.lap = cells
    else
      local side, th = next(o.ports)
      local rec = { x = o.at[1], y = o.at[2], side = side, th = th }
      if o.kind == "source" then L.src = rec elseif o.kind == "fixture" then L.fix = rec else L.hook = rec end
    end
  end
  return L
end
for f in (os.getenv("SEEDS") or ""):gmatch("%S+") do
  local def = dofile(f)
  if #def.grid == H and #def.grid[1] == W then
    local L = fromDef(def)
    local ok, r = pcall(evaluate, toDef(L))
    if ok and r then pool[#pool + 1] = { L = L, r = r, s = score(r) } else print("семя не годно: " .. f) end
  end
end
local t0 = os.clock()
local tried, valid = 0, 0
local reasons, firstErr = {}, nil
local bestPct, bestSmart = 0, 1e9
local front = {}
local archive = {}
local function dominates(a, b)
  return a.pct >= b.pct and a.smart <= b.smart and a.deep >= math.min(b.deep, 8) and (a.pct > b.pct or a.smart < b.smart)
end
local function record(L, r)
  if r.opt < 12 then return end
  for _, a in ipairs(archive) do
    if dominates(a.r, r) or (a.r.pct == r.pct and a.r.smart == r.smart) then return end
  end
  local keep = {}
  for _, a in ipairs(archive) do if not dominates(r, a.r) then keep[#keep + 1] = a end end
  keep[#keep + 1] = { L = L, r = r }
  archive = keep
  front = archive
end
while os.clock() - t0 < secs do
  local L
  if #archive > 0 and math.random() < 0.5 then
    L = mutate(archive[math.random(#archive)].L)
  elseif #pool > 0 and math.random() < 0.7 then
    L = mutate(pool[math.random(#pool)].L)
  else
    L = randomLayout()
  end
  if L then
    tried = tried + 1
    local ok, r, why = pcall(evaluate, toDef(L))
    if not ok then why = "error"; if not firstErr then firstErr = tostring(r) end end
    if ok and not r then reasons[why or "?"] = (reasons[why or "?"] or 0) + 1 end
    if ok and r then
      valid = valid + 1
      local s = score(r)
      if #pool < 40 or s > pool[#pool].s then
        pool[#pool + 1] = { L = L, r = r, s = s }
        table.sort(pool, function(a, b) return a.s > b.s end)
        if #pool > 40 then pool[#pool] = nil end
      end
      if r.pct > bestPct then bestPct = r.pct end
      if r.smart < bestSmart then bestSmart = r.smart end
      record(L, r)
    end
  end
end
-- фронт Парето: скрытых ↑, обезьяна ↓
local pareto = {}
for _, a in ipairs(front) do
  local dominated = false
  for _, b in ipairs(front) do
    if (b.r.pct >= a.r.pct and b.r.smart <= a.r.smart) and (b.r.pct > a.r.pct or b.r.smart < a.r.smart) then dominated = true break end
  end
  if not dominated then pareto[#pareto + 1] = a end
end
table.sort(pareto, function(a, b) return a.r.pct > b.r.pct end)
local f = io.open(out, "w")
f:write(string.format("# envelope W=%d H=%d Lmax=%d seed=%d secs=%d: опробовано %d, годных (решаем, крюк обязателен, одна победа) %d\n",
  W, H, LMAX, seed, secs, tried, valid))
f:write(string.format("# лучшая доля скрытых %.1f %%, лучшая умная обезьяна %.3f %%\n", bestPct, bestSmart))
for i = 1, math.min(60, #pareto) do
  local a = pareto[i]
  f:write(string.format("скрытых %5.1f %% | обезьяна %8.3f %% | глубина %2d | ходов %2d | состояний %4d (живых %d, скрытых %d, видимых %d)\n",
    a.r.pct, a.r.smart, a.r.deep, a.r.opt, a.r.n, a.r.live, a.r.hid, a.r.vis))
  for y = 1, H do f:write("    " .. table.concat(a.L.g[y]) .. "\n") end
  f:write(string.format("    S=%d,%d:%s=%s F=%d,%d:%s=%s T=%d,%d:%s=%s LAP=", a.L.src.x, a.L.src.y, a.L.src.side, a.L.src.th,
    a.L.fix.x, a.L.fix.y, a.L.fix.side, a.L.fix.th, a.L.hook.x, a.L.hook.y, a.L.hook.side, a.L.hook.th))
  local t = {}
  for _, c in ipairs(a.L.lap) do t[#t + 1] = c[1] .. "," .. c[2] end
  f:write(table.concat(t, ";") .. "\n")
end
f:write("# пул (по составной оценке):\n")
for i = 1, math.min(10, #pool) do
  local a = pool[i]
  f:write(string.format("скрытых %5.1f %% | обезьяна %8.3f %% | глубина %2d | ходов %2d | состояний %4d\n", a.r.pct, a.r.smart, a.r.deep, a.r.opt, a.r.n))
end
f:close()
local rs = {}
for k, v in pairs(reasons) do rs[#rs + 1] = k .. "=" .. v end
print("отсев: " .. table.concat(rs, " ") .. (firstErr and (" | ошибка: " .. firstErr) or ""))
print(string.format("опробовано %d, годных %d; лучшая доля скрытых %.1f %%, лучшая обезьяна %.3f %% → %s", tried, valid, bestPct, bestSmart, out))
