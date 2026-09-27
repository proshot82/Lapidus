-- build/l6/search.lua spec.lua секунд seed — локальный поиск раскладки кв. 6: стены в клетках «?»,
-- для каждой раскладки — все старты (Лапидус + ниппель на спине) через общий граф (build/l6/union.lua).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local U = dofile("build/l6/union.lua")
local spec = dofile(arg[1])
local budget = tonumber(arg[2] or "120")
local seed = tonumber(arg[3] or "1")
local rs = (seed * 7919 + 17) % 2147483647
local function rnd() rs = (rs * 16807) % 2147483647; return rs / 2147483647 end
local W, H = #spec.grid[1], #spec.grid
local FREE = {}
for y = 1, H do for x = 1, W do if spec.grid[y]:sub(x, x) == "?" then FREE[#FREE + 1] = { x, y } end end end

local function mkdef(cells)
  local grid = {}
  for y = 1, H do grid[y] = table.concat(cells[y]) end
  local objs = {}
  for _, o in ipairs(spec.objects) do objs[#objs + 1] = o end
  objs[#objs + 1] = { kind = "lapidus", cells = spec.lapHolder, head = 2 }
  return { id = 6, flat = 6, name = spec.name, length = spec.length, pressure = 0, grid = grid,
    objects = objs }
end

local function startsFor(def, lvl)
  local occ = {}
  local nipQ
  for q, p in ipairs(lvl.pieces) do if p.tag == spec.carry then nipQ = q else occ[p.start] = true end end
  local starts, meta, seenK = {}, {}, {}
  local L1, L2 = spec.startLen[1], spec.startLen[2]
  local function empty(c) return c ~= 0 and lvl.cell[c] == R.EMPTY and not occ[c] end
  local function try(body)
    for bi = 1, #body do
      local up = lvl.nb[body[bi]][R.UP]
      local onBody = false
      for _, c in ipairs(body) do if c == up then onBody = true end end
      if up ~= 0 and empty(up) and not onBody then
        -- состояние: тело body (от ног к голове), ниппель на up
        local st = { body = {}, pos = {}, asm = {}, fixed = {}, dead = false }
        for i = 1, #body do st.body[i] = body[i] end
        for q, p in ipairs(lvl.pieces) do st.pos[q] = p.start; st.asm[q] = q; st.fixed[q] = not p.movable end
        st.pos[nipQ] = up
        local k0 = R.key(st)
        if R.settle(lvl, st) and not st.dead and R.key(st) == k0 and not R.isWin(lvl, st) then
          if not seenK[k0] then
            seenK[k0] = true
            starts[#starts + 1] = st
            local bb = {}; for i = 1, #body do bb[i] = body[i] end
            meta[#meta + 1] = { body = bb, nip = up }
          end
        end
      end
    end
  end
  local function ext(body, used, L)
    if #body == L then try(body); return end
    local c = body[#body]
    for d = 1, 4 do
      local t = lvl.nb[c][d]
      if empty(t) and not used[t] then
        used[t] = true; body[#body + 1] = t
        ext(body, used, L)
        body[#body] = nil; used[t] = nil
      end
    end
  end
  for L = L1, L2 do
    for c = 1, lvl.N do if empty(c) then ext({ c }, { [c] = true }, L) end end
  end
  return starts, meta
end

local function score(m)
  local s = 0
  local T = spec.target
  if m.opt < T.moves[1] then s = s - (T.moves[1] - m.opt) * 12 elseif m.opt > T.moves[2] then s = s - (m.opt - T.moves[2]) * 6 end
  s = s + math.min(m.opt, T.moves[2]) + math.min(m.deadPct, 95) * 0.2 + math.min(m.fb, 8) * 4 + math.min(m.traps, 12) * 1.5
  if m.maxw > 3 then s = s - (m.maxw - 3) * 15 end
  if m.wins ~= 1 then s = s - 200 end
  if m.firstErr and m.firstErr <= 2 then s = s + 4 end
  return s
end

local function evaluate(cells)
  local def = mkdef(cells)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  local starts, meta = startsFor(def, lvl)
  if #starts == 0 then return nil end
  local G = U.build(lvl, starts, spec.cap or 300000)
  if not G then return nil end
  local best, bm, bi
  for i = 1, #starts do
    local m = U.metrics(G, G.sid[i], false)
    if m and m.wins == 1 and m.maxw <= 3 then
      local sc = score(m)
      if not best or sc > best then best, bm, bi = sc, m, i end
    end
  end
  if not best then return nil end
  local mm = U.metrics(G, G.sid[bi], true)
  if mm.monkey > 1.0 then best = best - (mm.monkey - 1) * 30 end
  local walls, iso = 0, 0
  for _, f in ipairs(FREE) do
    local x, y = f[1], f[2]
    if cells[y][x] == "#" then
      walls = walls + 1
      local nbw = 0
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local xx, yy = x + d[1], y + d[2]
        if xx < 1 or xx > W or yy < 1 or yy > H or cells[yy][xx] == "#" then nbw = nbw + 1 end
      end
      if nbw == 0 then iso = iso + 1 end
    end
  end
  best = best - (spec.wallPenalty or 0.5) * walls - (spec.isoPenalty or 4) * iso
  return best, mm, meta[bi], G.n, lvl
end

local function copyCells(c) local n = {}; for y = 1, H do n[y] = {}; for x = 1, W do n[y][x] = c[y][x] end end; return n end
local base = {}
for y = 1, H do base[y] = {}; for x = 1, W do local ch = spec.grid[y]:sub(x, x); base[y][x] = (ch == "?") and "." or ch end end
local function randomCells()
  local c = copyCells(base)
  for _, f in ipairs(FREE) do c[f[2]][f[1]] = (rnd() < (spec.wallProb or 0.3)) and "#" or "." end
  return c
end
local function mutate(c0)
  local c = copyCells(c0)
  for _ = 1, 1 + math.floor(rnd() * 2) do
    local f = FREE[1 + math.floor(rnd() * #FREE)]
    c[f[2]][f[1]] = (c[f[2]][f[1]] == "#") and "." or "#"
  end
  return c
end
local function keyOf(c) local t = {}; for y = 1, H do t[y] = table.concat(c[y]) end; return table.concat(t, "|") end

local pool, seen = {}, {}
local t0 = os.time()
local evals = 0
while os.time() - t0 < budget do
  local c
  if #pool == 0 or rnd() < 0.15 then c = randomCells() else c = mutate(pool[1 + math.floor(rnd() * math.min(#pool, 4))].c) end
  local k = keyOf(c)
  if not seen[k] then
    seen[k] = true
    evals = evals + 1
    local sc, m, meta, n = evaluate(c)
    if sc then
      pool[#pool + 1] = { c = c, sc = sc, m = m, meta = meta, n = n }
      table.sort(pool, function(a, b) return a.sc > b.sc end)
      while #pool > 8 do pool[#pool] = nil end
    end
  end
end
print(string.format("оценено раскладок: %d", evals))
local out = {}
for i, p in ipairs(pool) do
  local rows = {}
  for y = 1, H do rows[y] = table.concat(p.c[y]) end
  -- отметим старт
  local lvl = R.compile(mkdef(p.c))
  local g = {}
  for y = 1, H do g[y] = {}; for x = 1, W do g[y][x] = rows[y]:sub(x, x) end end
  for bi, cc in ipairs(p.meta.body) do local x, y = R.xy(lvl, cc); g[y][x] = (bi == #p.meta.body) and "H" or (bi == 1 and "f" or "o") end
  local nx, ny = R.xy(lvl, p.meta.nip); g[ny][nx] = "b"
  for _, o in ipairs(spec.objects) do if o.at and o.tag ~= spec.carry then g[o.at[2]][o.at[1]] = (o.kind == "source") and "S" or ((o.kind == "fixture") and "F" or "T") end end
  print(string.format("#%d score=%.1f opt=%d reach=%d (граф %d) dead=%.1f fb=%d traps=%d firstErr=%s safe1=%d short=%d w=%d monkey=%.2f",
    i, p.sc, p.m.opt, p.m.reach, p.n, p.m.deadPct, p.m.fb, p.m.traps, tostring(p.m.firstErr), p.m.safe1, p.m.count, p.m.maxw, p.m.monkey))
  for y = 1, H do print("   " .. table.concat(g[y])) end
  out[#out + 1] = { grid = rows, body = p.meta.body, nip = p.meta.nip }
end
-- сохранить лучших
local f = io.open(spec.out or "build/l6/best.lua", "w")
f:write("return {\n")
for _, o in ipairs(out) do
  f:write("  { grid = {")
  for _, r in ipairs(o.grid) do f:write(string.format("%q,", r)) end
  f:write("}, body = {" .. table.concat(o.body, ",") .. "}, nip = " .. o.nip .. " },\n")
end
f:write("}\n")
f:close()
