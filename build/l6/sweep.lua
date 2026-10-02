-- build/l6/sweep.lua список.lua [top] — для каждой раскладки: все старты (Лапидус + деталь на спине),
-- общий граф, лучшие старты по длине решения при строгих воротах и единственном выигрыше.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local U = dofile("build/l6/union.lua")
local list = dofile(arg[1])
local TOP = tonumber(arg[2] or "3")
local function startsFor(lvl, carryTag, L1, L2, fixedCarry)
  local occ, cq = {}, nil
  for q, p in ipairs(lvl.pieces) do if p.tag == carryTag then cq = q else occ[p.start] = true end end
  local starts, meta, seenK = {}, {}, {}
  local function empty(c) return c ~= 0 and lvl.cell[c] == R.EMPTY and not occ[c] end
  local function try(body)
    local spots = {}
    if fixedCarry then spots = { lvl.pieces[cq].start } else
      for bi = 1, #body do spots[#spots + 1] = lvl.nb[body[bi]][R.UP] end
    end
    for _, up in ipairs(spots) do
      local onBody = false
      for _, c in ipairs(body) do if c == up then onBody = true end end
      if up ~= 0 and empty(up) and not onBody then
        local st = { body = {}, pos = {}, asm = {}, fixed = {}, dead = false }
        for i = 1, #body do st.body[i] = body[i] end
        for q, p in ipairs(lvl.pieces) do st.pos[q] = p.start; st.asm[q] = q; st.fixed[q] = not p.movable end
        st.pos[cq] = up
        local k0 = R.key(st)
        if R.settle(lvl, st) and not st.dead and R.key(st) == k0 and not R.isWin(lvl, st) and not seenK[k0] then
          seenK[k0] = true
          local bb = {}; for i = 1, #body do bb[i] = body[i] end
          starts[#starts + 1] = st; meta[#meta + 1] = { body = bb, nip = up }
        end
      end
    end
  end
  local function ext(body, used, L)
    if #body == L then try(body); return end
    local c = body[#body]
    for d = 1, 4 do
      local t = lvl.nb[c][d]
      if empty(t) and not used[t] then used[t] = true; body[#body + 1] = t; ext(body, used, L); body[#body] = nil; used[t] = nil end
    end
  end
  for L = L1, L2 do for c = 1, lvl.N do if empty(c) then ext({ c }, { [c] = true }, L) end end end
  return starts, meta
end
local function draw(lvl, def, meta)
  local g = {}
  for y = 1, lvl.H do g[y] = {}; for x = 1, lvl.W do g[y][x] = def.grid[y]:sub(x, x) end end
  for _, o in ipairs(def.objects) do
    if o.at and o.kind ~= "fitting" then g[o.at[2]][o.at[1]] = ({ source = "S", fixture = "F", stub = "T", pipe = "=", porcelain = "p" })[o.kind] or "?" end
    if o.at and o.kind == "fitting" and o.tag ~= def.carry then g[o.at[2]][o.at[1]] = "c" end
  end
  for bi, c in ipairs(meta.body) do local x, y = R.xy(lvl, c); g[y][x] = (bi == #meta.body) and "H" or (bi == 1 and "f" or "o") end
  local nx, ny = R.xy(lvl, meta.nip); g[ny][nx] = "b"
  local out = {}
  for y = 1, lvl.H do out[y] = table.concat(g[y]) end
  return out
end
for _, def in ipairs(list) do
  local lvl = R.compile(def)
  local L1, L2 = (def.startLen or def.length)[1], (def.startLen or def.length)[2]
  local starts, meta = startsFor(lvl, def.carry or "nip", L1, L2, def.fixedCarry)
  local t0 = os.clock()
  local G = U.build(lvl, starts, 1500000, def.filter)
  if not G then print(def.tagname .. ": граф больше предела") else
    local rows = {}
    for i = 1, #starts do
      local m = U.metrics(G, G.sid[i], false)
      if m and m.wins == 1 and m.maxw <= 3 then rows[#rows + 1] = { i = i, m = m } end
    end
    for _, r in ipairs(rows) do
      local mm0 = U.metrics(G, G.sid[r.i], false)
      r.walk = mm0.walk
      r.key = mm0.opt - math.max(0, mm0.walk - 6) * 4
    end
    table.sort(rows, function(a, b) if a.key ~= b.key then return a.key > b.key end return a.m.fb > b.m.fb end)
    print(string.format("== %s: стартов %d, граф %d, годных %d (%.1fs)", def.tagname, #starts, G.n, #rows, os.clock() - t0))
    for k = 1, math.min(TOP, #rows) do
      local r = rows[k]
      local mm = U.metrics(G, G.sid[r.i], true)
      local pic = draw(lvl, def, meta[r.i])
      print(string.format("  [%s] opt=%d reach=%d dead=%.1f fb=%d traps=%d firstErr=%s forced=%d short=%d w=%d monkey=%.2f ev=%s walk=%d frun=%d",
        def.tagname, mm.opt, mm.reach, mm.deadPct, mm.fb, mm.traps, tostring(mm.firstErr), mm.safe1, mm.count, mm.maxw, mm.monkey, mm.ev, mm.walk, mm.frun))
      for _, l in ipairs(pic) do print("     " .. l) end
    end
  end
end
