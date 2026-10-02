-- tools/gen.lua — мутатор уровней (§7): перебирает вариации авторского скелета и отбирает
-- кандидатов под коридоры метрик и абляции. Решения не печатает.
-- Запуск: luajit tools/gen.lua gen/01.lua [секунд] [seed] [каталог]
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local S = require("core.search")
local SV = require("solver.solve")

local specPath = assert(arg[1], "usage: luajit tools/gen.lua gen/NN.lua [seconds] [seed] [outdir]")
local budget = tonumber(arg[2] or "300")
local seed = tonumber(arg[3] or "1")
local outdir = arg[4] or "build/gen"
os.execute("mkdir -p " .. outdir)
local spec = dofile(specPath)
local T = spec.target
local CAP = spec.searchCap or math.floor(T.states / 4)
local MINST = spec.minStates or math.floor(T.states / 20)
local W, H = #spec.grid[1], #spec.grid
local SIDES = { "up", "right", "down", "left" }
local DXY = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }

local rs = (seed * 7919 + 17) % 2147483647
local function rnd() rs = (rs * 16807) % 2147483647; return rs / 2147483647 end
local function rint(a, b) return a + math.floor(rnd() * (b - a + 1)) end
local function pick(t) return t[rint(1, #t)] end

local FREE, FREEB = {}, {}
for y = 1, H do
  for x = 1, W do
    if spec.grid[y]:sub(x, x) == "?" then
      if y == H then FREEB[#FREEB + 1] = { x, y } else FREE[#FREE + 1] = { x, y } end
    end
  end
end
local NOBJ = #spec.objects

local function cellAt(g, x, y)
  if x < 1 or x > W or y < 1 or y > H then return "#" end
  return g.cells[y][x]
end
local function copyG(g)
  local c = { cells = {}, objs = {}, lap = {} }
  for y = 1, H do c.cells[y] = {}; for x = 1, W do c.cells[y][x] = g.cells[y][x] end end
  for i = 1, NOBJ do local o = g.objs[i]; if o then c.objs[i] = { o[1], o[2], o[3] } end end
  for i, p in ipairs(g.lap) do c.lap[i] = { p[1], p[2] } end
  return c
end
local function occSet(g, skipObj, withLap)
  local occ = {}
  for i = 1, NOBJ do local o = g.objs[i]; if o and i ~= skipObj then occ[o[2] * 100 + o[1]] = true end end
  if withLap then for _, p in ipairs(g.lap) do occ[p[2] * 100 + p[1]] = true end end
  return occ
end
local function portsOf(o, opt) if o.portsOptions then return o.portsOptions[opt] end return o.ports end

local function objOK(g, i, x, y, opt, occ)
  local o = spec.objects[i]
  if x <= 1 or x >= W or y <= 1 or y >= H then return false end
  if cellAt(g, x, y) ~= "." or occ[y * 100 + x] then return false end
  if o.kind ~= "fitting" and o.kind ~= "porcelain" then
    for side in pairs(portsOf(o, opt) or {}) do
      local d = DXY[side]
      if cellAt(g, x + d[1], y + d[2]) ~= "." then return false end
    end
    if o.mount ~= false then
      local touch = false
      for _, s in ipairs(SIDES) do local d = DXY[s]; if cellAt(g, x + d[1], y + d[2]) == "#" then touch = true end end
      if not touch then return false end
    end
  end
  return true
end

local function placeObj(g, i, occ)
  local o = spec.objects[i]
  local nopt = o.portsOptions and #o.portsOptions or 1
  for _ = 1, 80 do
    local x, y
    if o.at then x, y = o.at[1], o.at[2] else x, y = rint(o.area[1], o.area[3]), rint(o.area[2], o.area[4]) end
    local opt = rint(1, nopt)
    if objOK(g, i, x, y, opt, occ) then g.objs[i] = { x, y, opt }; return true end
  end
  return false
end

local function placeLap(g)
  local L = spec.lapidus
  local occ = occSet(g, nil, false)
  for _ = 1, 100 do
    local n = rint(L.len[1], L.len[2])
    local x, y = rint(L.area[1], L.area[3]), rint(L.area[2], L.area[4])
    if cellAt(g, x, y) == "." and not occ[y * 100 + x] then
      local cells, used, ok = { { x, y } }, { [y * 100 + x] = true }, true
      for k = 2, n do
        local cx, cy = cells[k - 1][1], cells[k - 1][2]
        local opts = {}
        for _, s in ipairs(SIDES) do
          local d = DXY[s]
          local nx, ny = cx + d[1], cy + d[2]
          if cellAt(g, nx, ny) == "." and not occ[ny * 100 + nx] and not used[ny * 100 + nx] then opts[#opts + 1] = { nx, ny } end
        end
        if #opts == 0 then ok = false; break end
        local c = pick(opts)
        cells[k] = c
        used[c[2] * 100 + c[1]] = true
      end
      if ok then g.lap = cells; return true end
    end
  end
  return false
end

local function randomGenome()
  local g = { cells = {}, objs = {}, lap = {} }
  for y = 1, H do g.cells[y] = {}; for x = 1, W do g.cells[y][x] = spec.grid[y]:sub(x, x) end end
  for _, c in ipairs(FREE) do g.cells[c[2]][c[1]] = (rnd() < (spec.wallProb or 0.3)) and "#" or "." end
  for _, c in ipairs(FREEB) do g.cells[c[2]][c[1]] = (rnd() < (spec.drainProb or 0)) and "~" or "#" end
  for i = 1, NOBJ do if not placeObj(g, i, occSet(g, i, false)) then return nil end end
  if not placeLap(g) then return nil end
  return g
end

local function repair(g)
  for i = 1, NOBJ do
    local o = g.objs[i]
    local occ = occSet(g, i, true)
    if not (o and objOK(g, i, o[1], o[2], o[3], occ)) then
      if not placeObj(g, i, occ) then return nil end
    end
  end
  local occ = occSet(g, nil, false)
  for _, p in ipairs(g.lap) do
    if cellAt(g, p[1], p[2]) ~= "." or occ[p[2] * 100 + p[1]] then
      if not placeLap(g) then return nil end
      break
    end
  end
  return g
end

local function mutate(g0)
  local g = copyG(g0)
  local r = rnd()
  if r < 0.35 and #FREE > 0 then
    for _ = 1, 2 do
      local c = pick(FREE)
      g.cells[c[2]][c[1]] = (g.cells[c[2]][c[1]] == "#") and "." or "#"
      if rnd() < 0.5 then break end
    end
  elseif r < 0.42 and #FREEB > 0 then
    local c = pick(FREEB)
    g.cells[c[2]][c[1]] = (g.cells[c[2]][c[1]] == "~") and "#" or "~"
  elseif r < 0.70 then
    local cand = {}
    for i, o in ipairs(spec.objects) do if o.area or o.portsOptions then cand[#cand + 1] = i end end
    if #cand > 0 then
      local i = pick(cand)
      local old = g.objs[i]
      g.objs[i] = nil
      if not placeObj(g, i, occSet(g, i, true)) then g.objs[i] = old end
    end
  elseif r < 0.88 then
    placeLap(g)
  else
    local rev = {}
    for k = #g.lap, 1, -1 do rev[#rev + 1] = g.lap[k] end
    g.lap = rev
  end
  return repair(g)
end

local function toDef(g)
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g.cells[y]) end
  local objects = {}
  for i, o in ipairs(spec.objects) do
    local c = { kind = o.kind, what = o.what, tag = o.tag, at = { g.objs[i][1], g.objs[i][2] } }
    local ports = portsOf(o, g.objs[i][3])
    if ports then c.ports = {}; for k, v in pairs(ports) do c.ports[k] = v end end
    objects[i] = c
  end
  local cells = {}
  for k, p in ipairs(g.lap) do cells[k] = { p[1], p[2] } end
  objects[NOBJ + 1] = { kind = "lapidus", cells = cells, head = #cells }
  return { id = spec.id, flat = spec.flat, name = spec.name, length = spec.length,
           pressure = spec.pressure, grid = grid, objects = objects }
end

local function normalize(g)
  if not g then return nil end
  if spec.near then
    local a, b = g.objs[spec.near[1]], g.objs[spec.near[2]]
    if math.abs(a[1] - b[1]) + math.abs(a[2] - b[2]) > spec.near[3] then return nil end
  end
  local def = toDef(g)
  local ok, lvl = pcall(R.compile, def)
  if not ok or #R.validate(lvl) > 0 then return nil end
  local okS, st = pcall(R.newState, lvl)
  if not okS or st.dead then return nil end
  for q = 1, NOBJ do
    if st.pos[q] == 0 or st.asm[q] ~= q or st.fixed[q] ~= (not lvl.pieces[q].movable) then return nil end
    local x, y = R.xy(lvl, st.pos[q])
    g.objs[q][1], g.objs[q][2] = x, y
  end
  g.lap = {}
  for k = 1, #st.body do local x, y = R.xy(lvl, st.body[k]); g.lap[k] = { x, y } end
  if R.isWin(lvl, st) then return nil end
  if spec.accept and not spec.accept(toDef(g)) then return nil end
  return g
end

local function isolatedWalls(g)
  local n = 0
  for _, c in ipairs(FREE) do
    local x, y = c[1], c[2]
    if g.cells[y][x] == "#" then
      local nb = 0
      for _, s in ipairs(SIDES) do local d = DXY[s]; if cellAt(g, x + d[1], y + d[2]) == "#" then nb = nb + 1 end end
      if nb == 0 then n = n + 1 end
    end
  end
  return n
end

local function scoreRes(res, g)
  local mm, dead, fb = res.minMoves, res.deadPct, res.falseBranches or 0
  local s = 0
  if mm < T.moves[1] then s = s - (T.moves[1] - mm) * 15 elseif mm > T.moves[2] then s = s - (mm - T.moves[2]) * 8 end
  if dead < T.dead then s = s - (T.dead - dead) * 4 end
  if fb < T.fb then s = s - (T.fb - fb) * 30 end
  if res.winStates > 1 then s = s - math.min(30, (res.winStates - 1) * 3) end
  s = s + math.min(mm, T.moves[2]) + math.min(dead, 95) * 0.3 + math.min(fb, 12) * 3
  if res.states < MINST then s = s - 80 * (1 - res.states / MINST) end
  local walls = 0
  for _, c in ipairs(FREE) do if g.cells[c[2]][c[1]] == "#" then walls = walls + 1 end end
  return s - 2 * isolatedWalls(g) - (spec.wallPenalty or 0.4) * walls
end

local STRICT = spec.strict
local STX = STRICT and require("solver.strict") or nil
local function passes(res, abl)
  if not res or not res.solvable then return false end
  if STRICT and (not res.monkey or res.monkey > STRICT.monkey or res.shortest > STRICT.shortest) then return false end
  if res.minMoves < T.moves[1] or res.minMoves > T.moves[2] then return false end
  if res.deadPct < T.dead or (res.falseBranches or 0) < T.fb then return false end
  if res.states < MINST then return false end
  if spec.uniqueWin and res.winStates ~= 1 then return false end
  for _, a in ipairs(abl or {}) do if a.solvable ~= false then return false end end
  return true
end

local function evaluate(g)
  local def = toDef(g)
  local lvl = R.compile(def)
  local r0, path = S.run(lvl, R.newState(lvl), CAP)
  if r0 ~= "found" then return -1e9 end
  local mm = #path
  if mm < math.floor(T.moves[1] * 0.6) then return -1e6 + mm * 100 - 2 * isolatedWalls(g) end
  if spec.preAblation then
    -- дешёвый отсев: абляция, решаемая уже ограниченным поиском, — кандидат с лазейкой
    for _, ab in ipairs(spec.ablations or {}) do
      local d2 = SV.applyAblation(SV.deepcopy(def), ab)
      local okc, lvl2 = pcall(R.compile, d2)
      if okc and #R.validate(lvl2) == 0 and S.run(lvl2, R.newState(lvl2), CAP, ab.filter) == "found" then return -1e7 end
    end
  end
  local res = SV.analyze(def, { cap = CAP })
  if res.capped or not res.solvable or (res.unstable or 0) > 0 then return -1e8 end
  local sc = scoreRes(res, g)
  local abl = {}
  for _, ab in ipairs(spec.ablations or {}) do
    local d2 = SV.applyAblation(SV.deepcopy(def), ab)
    local okc, lvl2 = pcall(R.compile, d2)
    local solvable = false
    if okc and #R.validate(lvl2) == 0 then
      local r2 = S.run(lvl2, R.newState(lvl2), CAP * 2, ab.filter)
      if r2 == "found" then solvable = true elseif r2 == "unknown" then solvable = "unknown" end
    end
    abl[#abl + 1] = { name = ab.name, solvable = solvable }
    if solvable ~= false then sc = sc - 300 end
  end
  if STRICT then
    local sx = STX.check(def, CAP)
    if sx then
      res.monkey, res.shortest, res.maxWidth = sx.monkey, sx.shortest, sx.maxWidth
      if sx.monkey > STRICT.monkey then sc = sc - (sx.monkey - STRICT.monkey) * 25 end
      if sx.shortest > STRICT.shortest then sc = sc - math.min(120, (sx.shortest - STRICT.shortest) * 4) end
    else
      sc = sc - 500
    end
  end
  return sc, res, abl
end

local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "B", porcelain = "P" }
local function ascii(d)
  local rows = {}
  for y = 1, #d.grid do rows[y] = {}; for x = 1, #d.grid[1] do rows[y][x] = d.grid[y]:sub(x, x) end end
  local legend = {}
  for i, o in ipairs(d.objects) do
    if o.kind == "lapidus" then
      for k, c in ipairs(o.cells) do rows[c[2]][c[1]] = (k == #o.cells) and "H" or ((k == 1) and "h" or "o") end
    else
      rows[o.at[2]][o.at[1]] = SYM[o.kind]
      local ps = {}
      for _, s in ipairs(SIDES) do if o.ports and o.ports[s] then ps[#ps + 1] = s .. ":" .. o.ports[s] end end
      legend[#legend + 1] = string.format("%s%d(%d,%d)[%s]", SYM[o.kind], i, o.at[1], o.at[2], table.concat(ps, ","))
    end
  end
  local out = {}
  for y = 1, #rows do out[y] = "  " .. table.concat(rows[y]) end
  return table.concat(out, "\n") .. "\n  " .. table.concat(legend, " ")
end

local function serialize(d, meta)
  local L = { "-- " .. meta, "return {" }
  L[#L + 1] = string.format("  id = %d, flat = %d, name = %q,", d.id, d.flat or d.id, d.name)
  L[#L + 1] = string.format("  length = { %d, %d }, pressure = %d,", d.length[1], d.length[2], d.pressure or 0)
  L[#L + 1] = string.format("  target = { moves = { %d, %d }, states = %d, dead = %d, fb = %d },",
    T.moves[1], T.moves[2], T.states, T.dead, T.fb)
  L[#L + 1] = "  grid = {"
  for _, row in ipairs(d.grid) do L[#L + 1] = string.format("    %q,", row) end
  L[#L + 1] = "  },"
  L[#L + 1] = "  objects = {"
  for _, o in ipairs(d.objects) do
    if o.kind == "lapidus" then
      local cs = {}
      for _, c in ipairs(o.cells) do cs[#cs + 1] = string.format("{ %d, %d }", c[1], c[2]) end
      L[#L + 1] = string.format("    { kind = \"lapidus\", cells = { %s }, head = %d },", table.concat(cs, ", "), o.head)
    else
      local ps = {}
      for _, s in ipairs(SIDES) do if o.ports and o.ports[s] then ps[#ps + 1] = s .. " = \"" .. o.ports[s] .. "\"" end end
      local extra = ""
      if o.what then extra = extra .. string.format(" what = %q,", o.what) end
      if o.tag then extra = extra .. string.format(" tag = %q,", o.tag) end
      L[#L + 1] = string.format("    { kind = %q,%s at = { %d, %d }%s },", o.kind, extra, o.at[1], o.at[2],
        (#ps > 0) and (", ports = { " .. table.concat(ps, ", ") .. " }") or "")
    end
  end
  L[#L + 1] = "  },"
  L[#L + 1] = "  ablations = {"
  for _, ab in ipairs(spec.ablations or {}) do
    local parts = { string.format("name = %q", ab.name) }
    if ab.flip then parts[#parts + 1] = string.format("flip = %q", ab.flip) end
    if ab.remove then parts[#parts + 1] = string.format("remove = %q", ab.remove) end
    if ab.pressure then parts[#parts + 1] = string.format("pressure = %d", ab.pressure) end
    L[#L + 1] = "    { " .. table.concat(parts, ", ") .. " },"
  end
  L[#L + 1] = "  },"
  L[#L + 1] = "}"
  return table.concat(L, "\n") .. "\n"
end

local function keyOf(g)
  local d = toDef(g)
  local parts = { table.concat(d.grid, "|") }
  for _, o in ipairs(d.objects) do
    if o.at then
      parts[#parts + 1] = o.at[1] .. "," .. o.at[2]
      if o.ports then for _, s in ipairs(SIDES) do parts[#parts + 1] = o.ports[s] or "-" end end
    end
  end
  for _, c in ipairs(g.lap) do parts[#parts + 1] = c[1] .. "." .. c[2] end
  return table.concat(parts, ";")
end

local pool, seen = {}, {}
-- spec.init = { "путь/к/кандидату.lua", ... } — затравка пула готовыми кандидатами (локальный поиск)
for _, path in ipairs(spec.init or {}) do
  local d = dofile(path)
  local g = { cells = {}, objs = {}, lap = {} }
  for y = 1, H do g.cells[y] = {}; for x = 1, W do g.cells[y][x] = d.grid[y]:sub(x, x) end end
  local k = 0
  for _, o in ipairs(d.objects) do
    if o.kind == "lapidus" then
      local cs = o.cells
      if o.head == 1 then local r = {}; for i = #cs, 1, -1 do r[#r + 1] = cs[i] end; cs = r end
      for i, c in ipairs(cs) do g.lap[i] = { c[1], c[2] } end
    else k = k + 1; g.objs[k] = { o.at[1], o.at[2], 1 } end
  end
  g = normalize(g)
  if g then
    seen[keyOf(g)] = true
    local sc, res, abl = evaluate(g)
    if sc > -1e8 then pool[#pool + 1] = { g = g, sc = sc, res = res, abl = abl, pass = passes(res, abl) } end
  end
end
table.sort(pool, function(a, b) return a.sc > b.sc end)
local t0 = os.clock()
local w0, lastSnap = os.time(), os.time()
local report
local evals, valid, passCount = 0, 0, 0
local function searchLoop()
while os.time() - w0 < budget do
  if os.time() - lastSnap >= 20 then report(); lastSnap = os.time() end
  local g
  if #pool == 0 or rnd() < 0.2 then
    g = normalize(randomGenome())
  else
    local parent = (rnd() < 0.5) and pool[1] or pick(pool)
    g = normalize(mutate(parent.g))
  end
  if g then
    local k = keyOf(g)
    if not seen[k] then
      seen[k] = true
      evals = evals + 1
      local sc, res, abl = evaluate(g)
      if sc > -1e8 then
        valid = valid + 1
        local ok = passes(res, abl)
        if ok then passCount = passCount + 1 end
        pool[#pool + 1] = { g = g, sc = sc, res = res, abl = abl, pass = ok }
        table.sort(pool, function(a, b) return a.sc > b.sc end)
        while #pool > 10 do pool[#pool] = nil end
      end
    end
  end
end

end

function report()
  local out = {}
  out[#out + 1] = string.format("%s: evals=%d solvable=%d passing=%d wall=%ds cap=%d", spec.name, evals, valid, passCount, os.time() - w0, CAP)
  for rank = 1, math.min(4, #pool) do
    local c = pool[rank]
    local d = toDef(c.g)
    local r = c.res
    local meta
    if r and r.states then
      local ab = {}
      for _, a in ipairs(c.abl or {}) do ab[#ab + 1] = a.name .. "=" .. tostring(a.solvable) end
      meta = string.format("score=%.1f pass=%s states=%d minMoves=%d dead=%.1f%% fb=%d wins=%d abl[%s]" .. (c.res.monkey and string.format(" наобум=%.2f%%%% кратчайших=%d", c.res.monkey, c.res.shortest) or ""),
        c.sc, tostring(c.pass), r.states, r.minMoves, r.deadPct, r.falseBranches or 0, r.winStates, table.concat(ab, "; "))
    else
      meta = string.format("score=%.1f (слишком лёгкий кандидат)", c.sc)
    end
    out[#out + 1] = ("-"):rep(60)
    out[#out + 1] = meta
    out[#out + 1] = ascii(d)
    local f = io.open(string.format("%s/%02d_c%d.lua", outdir, spec.id, rank), "w")
    f:write(serialize(d, meta))
    f:close()
  end
  local f = io.open(string.format("%s/%02d.txt", outdir, spec.id), "w")
  f:write(table.concat(out, "\n") .. "\n")
  f:close()
end
searchLoop()
report()
print("done " .. spec.name)
