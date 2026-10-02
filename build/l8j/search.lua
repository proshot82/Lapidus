-- build/l8j/search.lua seed.lua out_prefix iters [seed] — мутатор вокруг авторского скелета (DESIGN §7: «мутатор
-- перебирает вариации авторского скелета»). Двигает свободные клетки-стены внутри рамки, подвижные детали и старт
-- Лапидуса; мойка, стояк и слив — неподвижный скелет. Оценка — ворота check.lua (без строгого прогона).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local seedPath, outPrefix, iters, rs = arg[1], arg[2], tonumber(arg[3] or 2000), tonumber(arg[4] or os.time())
math.randomseed(rs)
local base = dofile(seedPath)
local function copy(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = copy(v) end return c end
local lockCells = base.lock or {} -- клетки, которые не трогаем: "x,y"
local lockX = tonumber(os.getenv("LOCKX") or "0") -- столбцы 1..LOCKX не трогаем
local function eval(def)
  for _, o in ipairs(def.objects) do if o.kind == "lapidus" then for _, c in ipairs(o.cells) do
    if c[1] < 2 or c[2] < 2 or c[1] > #def.grid[1] - 1 or c[2] > #def.grid - 1 then return nil end end end end
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  local ok2, errs, warns = pcall(R.validate, lvl)
  if not ok2 then return nil end
  if #errs > 0 or #warns > 0 then return nil end
  local G = SV.explore(lvl, tonumber(os.getenv("CAP") or "120000"))
  if not G then return nil end
  if not G.firstWin then SV.freeGraph(G) return { solvable = false } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local M = V.measure(G, good, VL.newbie)
  -- двери по половинам
  local hidden = M.hidden
  local path = M.path
  local halves = { 0, 0 }
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if hidden[G.edges.p[e]] then c = c + 1 end end
    if c > 0 then local h = (k - 1) < (#path - 1) / 2 and 1 or 2; halves[h] = halves[h] + 1 end
  end
  -- выигрышных конфигураций
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  -- ширина коридора кратчайших (как build/l8j/width.lua)
  local opt = M.opt
  local rev = {}
  for i = 1, G.n do for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]; local t = rev[j]; if not t then t = {}; rev[j] = t end; t[#t+1] = i end end
  local dw, qq, hh = {}, {}, 1
  for i = 1, G.n do if G.flag[i] == 1 then dw[i] = 0; qq[#qq+1] = i end end
  while hh <= #qq do local u = qq[hh]; hh = hh + 1; for _, v in ipairs(rev[u] or {}) do if not dw[v] and G.flag[v] ~= 2 then dw[v] = dw[u] + 1; qq[#qq+1] = v end end end
  local wd, width = {}, 1
  for i = 1, G.n do if dw[i] and G.depth[i] + dw[i] == opt then wd[G.depth[i]] = (wd[G.depth[i]] or 0) + 1; if wd[G.depth[i]] > width then width = wd[G.depth[i]] end end end
  local r = { solvable = true, opt = M.opt, hid = M.hiddenPct, smart = M.smart, deep = M.maxDeep, n = G.n, h1 = halves[1], h2 = halves[2], nwin = nwin, width = width }
  SV.freeGraph(G); require("ffi").C.free(good)
  return r
end
local function score(r)
  if not r then return -1e9 end
  if not r.solvable then return -1e8 end
  local s = 0
  s = s - 4 * math.max(0, 28 - r.opt) - 4 * math.max(0, r.opt - 38)
  s = s + math.min(r.hid, 45)
  s = s + 2 * math.min(r.deep, 14)
  s = s - 40 * math.max(0, r.smart - 0.15)
  s = s + 8 * math.min(r.h1, 1) + 8 * math.min(r.h2, 1)
  if r.nwin > 1 then s = s - 20 end
  s = s - 4 * math.max(0, (r.width or 1) - 3)
  return s
end
local function occupied(def)
  local occ = {}
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end
    else occ[o.at[1] .. "," .. o.at[2]] = true end
  end
  return occ
end
local function setCell(def, x, y, ch) local r = def.grid[y]; def.grid[y] = r:sub(1, x - 1) .. ch .. r:sub(x + 1) end
local function mutate(def)
  local d = copy(def)
  local H, W = #d.grid, #d.grid[1]
  local k = math.random(1, 10)
  local occ = occupied(d)
  if k <= 5 then -- переключить стену
    for _ = 1, 50 do
      local x, y = math.random(2, W - 1), math.random(2, H - 1)
      local key = x .. "," .. y
      if not occ[key] and not lockCells[key] and x > lockX then
        local c = d.grid[y]:sub(x, x)
        if c == "#" then setCell(d, x, y, ".") return d elseif c == "." then setCell(d, x, y, "#") return d end
      end
    end
  elseif k <= 8 then -- сдвинуть подвижную деталь
    local mv = {}
    for i, o in ipairs(d.objects) do if (o.kind == "fitting" or o.kind == "porcelain") and not (os.getenv("LOCKPIECES") and o.at[1] <= lockX) then mv[#mv + 1] = o end end
    if #mv > 0 then
      local o = mv[math.random(#mv)]
      for _ = 1, 50 do
        local x, y = math.random(2, W - 1), math.random(2, H - 1)
        if d.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] and (x > lockX or not o.lockedPiece) then o.at = { x, y } return d end
      end
    end
  else -- сдвинуть Лапидуса
    for _, o in ipairs(d.objects) do if o.kind == "lapidus" then
      local dx, dy = math.random(-2, 2), math.random(-2, 2)
      local nc = {}
      for _, c in ipairs(o.cells) do nc[#nc + 1] = { c[1] + dx, c[2] + dy } end
      o.cells = nc
      return d
    end end
  end
  return d
end
local function dump(def, r, path)
  local f = io.open(path, "w")
  f:write(string.format("-- мутатор: ходов %d, скрытых %.0f%%, обезьяна %.2f%%, глубина %d, двери %d/%d, состояний %d, выигрышных %d, ширина %d\n",
    r.opt, r.hid, r.smart, r.deep, r.h1, r.h2, r.n, r.nwin, r.width or 0))
  f:write('local okV, vis = pcall(dofile, "build/l8j/vis.lua")\nreturn {\n  visibleLoss = okV and vis or nil,\n')
  if def.washOk then f:write("  washOk = true,\n") end
  if def.mustLift then f:write('  mustLift = { "' .. table.concat(def.mustLift, '", "') .. '" },\n') end
  f:write(string.format('  id = 8, flat = 8, name = "%s",\n  length = { %d, %d }, pressure = 0, tile = "mint",\n  grid = {\n', def.name, def.length[1], def.length[2]))
  for _, g in ipairs(def.grid) do f:write('    "' .. g .. '",\n') end
  f:write("  },\n  objects = {\n")
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then
      local cs = {}
      for _, c in ipairs(o.cells) do cs[#cs + 1] = string.format("{ %d, %d }", c[1], c[2]) end
      f:write(string.format("    { kind = \"lapidus\", cells = { %s }, head = %d },\n", table.concat(cs, ", "), o.head))
    else
      local ps = {}
      for _, s in ipairs({ "up", "right", "down", "left" }) do if o.ports and o.ports[s] then ps[#ps + 1] = s .. ' = "' .. o.ports[s] .. '"' end end
      f:write(string.format('    { kind = "%s",%s%s at = { %d, %d }%s },\n', o.kind, o.what and (' what = "' .. o.what .. '",') or "", o.tag and (' tag = "' .. o.tag .. '",') or "",
        o.at[1], o.at[2], #ps > 0 and (", ports = { " .. table.concat(ps, ", ") .. " }") or ""))
    end
  end
  f:write("  },\n  ablations = {")
  for _, o in ipairs(def.objects) do if o.tag then f:write(string.format(' { name = "без %s", remove = "%s" },', o.tag, o.tag)) end end
  f:write(" },\n}\n")
  f:close()
end
local cur = copy(base); cur.lock = nil; cur.visibleLoss = base.visibleLoss
local cr = eval(cur); local cs = score(cr)
local best, br, bs = cur, cr, cs
print("старт", cs, cr and cr.opt)
local T0 = 6
for it = 1, iters do
  local cand = mutate(cur)
  cand.visibleLoss = base.visibleLoss
  local r = eval(cand)
  local s = score(r)
  local T = T0 * (1 - it / iters) + 0.3
  if s >= cs or math.random() < math.exp((s - cs) / T) then cur, cr, cs = cand, r, s end
  if s > bs and r and r.solvable then
    best, br, bs = cand, r, s
    dump(best, br, outPrefix .. ".lua")
    print(string.format("%d: score %.1f ходов %d скрытых %.0f%% обез %.2f глуб %d двери %d/%d n=%d win=%d ширина %d", it, s, r.opt, r.hid, r.smart, r.deep, r.h1, r.h2, r.n, r.nwin, r.width))
    io.stdout:flush()
  end
end
