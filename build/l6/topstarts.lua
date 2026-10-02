-- все хорошие старты для заданной раскладки (файл уровня): метрики + картинка старта
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local U = dofile("build/l6/union.lua")
local def = dofile(arg[1])
local N = tonumber(arg[2] or "12")
local lvl = R.compile(def)
local occ, cq = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then cq = q else occ[p.start] = true end end
local starts, meta, seenK = {}, {}, {}
local function empty(c) return c ~= 0 and lvl.cell[c] == R.EMPTY and not occ[c] end
local function try(body)
  for bi = 1, #body do
    local up = lvl.nb[body[bi]][R.UP]
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
for L = def.length[1], def.length[2] do for c = 1, lvl.N do if empty(c) then ext({ c }, { [c] = true }, L) end end end
local G = U.build(lvl, starts, 3000000)
local rows = {}
for i = 1, #starts do
  local m = U.metrics(G, G.sid[i], true)
  if m and m.wins == 1 and m.maxw <= 3 and m.monkey <= 1 then rows[#rows + 1] = { i = i, m = m } end
end
table.sort(rows, function(a, b)
  local ka = a.m.opt - math.max(0, a.m.walk - 4) * 3
  local kb = b.m.opt - math.max(0, b.m.walk - 4) * 3
  if ka ~= kb then return ka > kb end
  return a.m.fb > b.m.fb end)
print("стартов " .. #starts .. ", годных " .. #rows .. ", граф " .. G.n)
for k = 1, math.min(N, #rows) do
  local r = rows[k]
  local mt = meta[r.i]
  local g = {}
  for y = 1, lvl.H do g[y] = {}; for x = 1, lvl.W do g[y][x] = def.grid[y]:sub(x, x) end end
  for _, o in ipairs(def.objects) do if o.at and o.tag ~= "nip" then g[o.at[2]][o.at[1]] = (o.kind == "source") and "S" or "F" end end
  for bi, c in ipairs(mt.body) do local x, y = R.xy(lvl, c); g[y][x] = (bi == #mt.body) and "H" or (bi == 1 and "f" or "o") end
  local nx, ny = R.xy(lvl, mt.nip); g[ny][nx] = "b"
  local cs = {}
  for _, c in ipairs(mt.body) do local x, y = R.xy(lvl, c); cs[#cs + 1] = x .. "," .. y end
  print(string.format("#%d opt=%d dead=%.1f fb=%d traps=%d fe=%s short=%d w=%d monkey=%.3f ev=%s walk=%d frun=%d  lap[%s] nip(%d,%d)",
    k, r.m.opt, r.m.deadPct, r.m.fb, r.m.traps, tostring(r.m.firstErr), r.m.count, r.m.maxw, r.m.monkey, r.m.ev, r.m.walk, r.m.frun, table.concat(cs, " "), nx, ny))
  for y = 1, lvl.H do print("     " .. table.concat(g[y])) end
end
