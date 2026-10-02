-- build/l7j/mut.lua база.lua секунд seed [имя] — мутатор вокруг ручного скелета (DESIGN §7: «мутатор перебирает вариации
-- авторского скелета»). Держит заданную финальную сборку (def.want = { tag = {x,y} }), двигает стены, детали, старт.
-- def.protect = { {x,y}, ... } — клетки, которые не трогать. Пишет лучшего в build/l7j/mut/<имя>.lua. Решения не печатает.
package.path = "./?.lua;" .. package.path
local MET = dofile("build/l7j/met.lua")
local R = require("core.rules")
local SV = require("solver.solve")
local base = dofile(arg[1])
local budget, seed = tonumber(arg[2] or 600), tonumber(arg[3] or 1)
local name = arg[4] or ("m" .. seed)
os.execute("mkdir -p build/l7j/mut")
local rs = (seed * 7919 + 17) % 2147483647
local function rnd() rs = (rs * 16807) % 2147483647; return rs / 2147483647 end
local function rint(a, b) return a + math.floor(rnd() * (b - a + 1)) end
local W, H = #base.grid[1], #base.grid
local protect = {}
for _, c in ipairs(base.protect or {}) do protect[c[2] * 100 + c[1]] = true end
for _, o in ipairs(base.objects) do if o.kind ~= "lapidus" and o.kind ~= "fitting" and o.kind ~= "porcelain" then protect[o.at[2] * 100 + o.at[1]] = true end end
local fixedPieces = {}
for _, t in ipairs(base.fixedPieces or {}) do fixedPieces[t] = true end
local function copy(d) return SV.deepcopy(d) end
MET.pre = function(r, def)
  if r.ncfg ~= 1 then return false end
  local lo, hi = (def.optRange or { 24, 34 })[1], (def.optRange or { 24, 34 })[2]
  if r.opt < lo - 8 or r.opt > hi + 6 then return false end
  for q, p in ipairs(r.lvl.pieces) do
    if p.movable and def.want and def.want[p.tag] then
      local w = def.want[p.tag]
      if r.win.pos[q] ~= R.idx(r.lvl, w[1], w[2]) or not r.win.fixed[q] then return false end
    end
  end
  return true
end
local function score(def)
  local r = MET.eval(def, def.cap or 120000)
  if r.err then return -1e6, r end
  local s = 0
  if r.ncfg ~= 1 then s = s - 300 end
  for q, p in ipairs(r.lvl.pieces) do
    if p.movable and def.want and def.want[p.tag] then
      local w = def.want[p.tag]
      if r.win.pos[q] ~= R.idx(r.lvl, w[1], w[2]) or not r.win.fixed[q] then s = s - 500 end
    end
  end
  local lo, hi = (def.optRange or { 24, 34 })[1], (def.optRange or { 24, 34 })[2]
  if r.opt < lo then s = s - (lo - r.opt) * 12 elseif r.opt > hi then s = s - (r.opt - hi) * 12 end
  if r.width > 3 then s = s - (r.width - 3) * 8 end
  if r.walk > 6 then s = s - (r.walk - 6) * 5 end
  if r.hid < 25 then s = s - (25 - r.hid) * 3 else s = s + math.min(r.hid, 60) * 0.4 end
  if r.deep < 8 then s = s - (8 - r.deep) * 6 end
  if r.smart > 0.2 then s = s - (r.smart - 0.2) * 60 end
  if r.d2 > 0 then s = s + 8 end
  if r.d1 > 0 then s = s + 8 end
  s = s + math.min(r.events, 8) * 2
  if def.wantStep and r.stepOn > 0 then s = s + 10 end
  local walls = 0
  for y = 2, H - 1 do for x = 2, W - 1 do if def.grid[y]:sub(x, x) == "#" then walls = walls + 1 end end end
  s = s - walls * (def.wallCost or 0.7)
  return s, r
end
local function setCell(def, x, y, ch) local row = def.grid[y]; def.grid[y] = row:sub(1, x - 1) .. ch .. row:sub(x + 1) end
local function occupied(d, x, y)
  for _, o in ipairs(d.objects) do
    if o.kind == "lapidus" then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then return true end end
    elseif o.at[1] == x and o.at[2] == y then return true end
  end
  return false
end
local function mutate(def)
  local d = copy(def)
  local k = rint(1, 10)
  if k <= 5 then
    for _ = 1, 30 do
      local x, y = rint(2, W - 1), rint(2, H - 1)
      if not protect[y * 100 + x] and not occupied(d, x, y) and d.grid[y]:sub(x, x) ~= "~" then
        setCell(d, x, y, d.grid[y]:sub(x, x) == "#" and "." or "#"); break
      end
    end
  elseif k <= 8 then
    local movs = {}
    for _, o in ipairs(d.objects) do if (o.kind == "fitting" or o.kind == "porcelain") and not fixedPieces[o.tag] then movs[#movs + 1] = o end end
    if #movs > 0 then
      local o = movs[rint(1, #movs)]
      for _ = 1, 30 do
        local x, y = rint(2, W - 1), rint(2, H - 1)
        if d.grid[y]:sub(x, x) == "." and d.grid[y + 1]:sub(x, x) == "#" and not protect[y * 100 + x] and not occupied(d, x, y) then o.at = { x, y }; break end
      end
    end
  elseif not base.fixedLap then
    for _, o in ipairs(d.objects) do if o.kind == "lapidus" then
      local n = #o.cells
      for _ = 1, 30 do
        local x, y = rint(2, W - n), rint(2, H - 1)
        local ok = true
        for i = 0, n - 1 do if d.grid[y]:sub(x + i, x + i) ~= "." or d.grid[y + 1]:sub(x + i, x + i) ~= "#" or occupied(d, x + i, y) then ok = false end end
        if ok then o.cells = {} for i = 0, n - 1 do o.cells[#o.cells + 1] = { x + i, y } end; o.head = (rnd() < 0.5) and 1 or n; break end
      end
    end end
  end
  return d
end
local function dump(def, s, r, path)
  local lines = { string.format("-- l7j %s: мутатор build/l7j/mut.lua от %s (seed %d). Решение не пишется.", name, arg[1], seed),
    string.format("-- метрики: ходов %d, ширина %d, прогулка %d, скрытых %.0f%%, обезьяна %.2f, глубина %d, двери %d/%d, событий %d, сост %d, конфиг %d, счёт %.1f",
      r.opt, r.width, r.walk, r.hid, r.smart, r.deep, r.d1, r.d2, r.events, r.n, r.ncfg, s),
    'local okV, vis = pcall(dofile, "build/l6j/vis.lua")', "return {", "  visibleLoss = okV and vis or nil,",
    string.format('  id = 7, flat = 7, name = "%s",', name),
    string.format('  length = { %d, %d }, pressure = 0, tile = "mint",', def.length[1], def.length[2]),
    "  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },", "  grid = {" }
  for _, row in ipairs(def.grid) do lines[#lines + 1] = string.format('    "%s",', row) end
  lines[#lines + 1] = "  },"; lines[#lines + 1] = "  objects = {"
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then
      local cs = {} for _, c in ipairs(o.cells) do cs[#cs + 1] = string.format("{ %d, %d }", c[1], c[2]) end
      lines[#lines + 1] = string.format('    { kind = "lapidus", cells = { %s }, head = %d },', table.concat(cs, ", "), o.head)
    else
      local ps = {} for _, sd in ipairs({ "up", "right", "down", "left" }) do if o.ports and o.ports[sd] then ps[#ps + 1] = sd .. ' = "' .. o.ports[sd] .. '"' end end
      lines[#lines + 1] = string.format('    { kind = "%s",%s%s at = { %d, %d }, ports = { %s } },', o.kind, o.what and (' what = "' .. o.what .. '",') or "", o.tag and (' tag = "' .. o.tag .. '",') or "", o.at[1], o.at[2], table.concat(ps, ", "))
    end
  end
  lines[#lines + 1] = "  },"; lines[#lines + 1] = "  ablations = {"
  for _, a in ipairs(def.ablations or {}) do if a.remove then lines[#lines + 1] = string.format('    { name = "%s", remove = "%s" },', a.name, a.remove) end end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = '  texts = { request = "", hints = { "", "", "" } },'
  lines[#lines + 1] = "}"
  local f = io.open(path, "w"); f:write(table.concat(lines, "\n") .. "\n"); f:close()
end
local cur = copy(base)
local cs, cr = score(cur)
local best, bs, br = cur, cs, cr
print(string.format("старт: счёт %.1f %s", cs, cr.err or ""))
io.stdout:flush()
local t0 = os.time()
local it = 0
while os.time() - t0 < budget do
  it = it + 1
  local d = mutate(cur)
  if rnd() < 0.3 then d = mutate(d) end
  local s, r = score(d)
  if s >= cs or rnd() < 0.03 then
    cur, cs, cr = d, s, r
    if s > bs then
      best, bs, br = d, s, r
      dump(best, bs, br, "build/l7j/mut/" .. name .. ".lua")
      print(string.format("%d: счёт %.1f ходов %d шир %d прог %d скр %.0f%% обез %.2f глуб %d двери %d/%d", it, s, r.opt, r.width, r.walk, r.hid, r.smart, r.deep, r.d1, r.d2))
      io.stdout:flush()
    end
  end
  if cs < bs - 60 then cur, cs, cr = best, bs, br end
end
print("итераций", it)
