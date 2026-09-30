-- build/l3d/mut.lua база.lua итераций seed лог — мутатор авторского скелета (§7): переключает 1–2 клетки,
-- держит лучшего по «устойчивой» доле скрытых (минимум при кармане 4 и 5), дверям по половинам и прогулке.
-- Пишет в лог только сетки и метрики (без ходов).
package.path = "./?.lua;" .. package.path
local M = dofile("build/l3d/m.lua")
local SV = require("solver.solve")
local basePath, N, seed, logPath = arg[1], tonumber(arg[2] or 500), tonumber(arg[3] or 1), arg[4] or "build/l3d/mut.log"
math.randomseed(seed)
local base = dofile(basePath)
local occ = {}
for _, o in ipairs(base.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
local H, W = #base.grid, #base.grid[1]
local log = io.open(logPath, "a")
local cache = {}
local function eval(grid)
  local key = table.concat(grid, "|")
  if cache[key] ~= nil then return cache[key] end
  local d = SV.deepcopy(base); d.grid = grid
  local r4 = M.run(d, 4)
  local res = false
  if not (r4.err or r4.unsolv) and r4.nwin == 1 and r4.opt >= 15 and r4.opt <= 40 then
    local gw = M.wallDead(d)
    local dw = SV.deepcopy(base); dw.grid = gw
    local rw = M.run(dw, 4)
    local r5 = M.run(dw, 5)
    if rw.err or rw.unsolv then cache[key] = false return false end
    r4 = rw
    local ab = SV.ablations(dw, { cap = 3000000 })
    for _, a in ipairs(ab) do if a.solvable ~= false then cache[key] = false return false end end
    local s = math.min(r4.hid, r5.hid) + (r4.h2 >= 1 and 15 or 0) + (r5.h2 >= 1 and 15 or 0) + (r4.h1 >= 1 and 5 or 0) + (r5.h1 >= 1 and 5 or 0) - 3 * math.max(0, r4.maxwalk - 9)
    res = { s = s, r4 = r4, r5 = r5, gw = gw }
  end
  cache[key] = res
  return res
end
local function mutate(grid)
  local g = {}
  for y = 1, H do g[y] = grid[y] end
  local k = math.random(1, 2)
  for _ = 1, k do
    local x, y = math.random(2, W - 1), math.random(2, H - 1)
    if not occ[x .. "," .. y] then
      local ch = g[y]:sub(x, x)
      if ch == "." or ch == "#" then
        g[y] = g[y]:sub(1, x - 1) .. (ch == "." and "#" or ".") .. g[y]:sub(x + 1)
      end
    end
  end
  return g
end
local cur = base.grid
local cr = eval(cur)
local best = cr
log:write(string.format("== seed %d база %s: %s | карман5 %.1f%%\n", seed, basePath, M.fmt(cr.r4), cr.r5.hid)); log:flush()
for it = 1, N do
  local g = mutate(cur)
  local r = eval(g)
  if r and r.s >= cr.s then
    local improved = r.s > best.s
    cur, cr = g, r
    if improved then
      best = r
      log:write(string.format("[%d] s=%.1f %s | карман5 %.1f%% двери5 %s (%d/%d)\n", it, r.s, M.fmt(r.r4), r.r5.hid, r.r5.doors or "", r.r5.h1 or 0, r.r5.h2 or 0))
      for y = 1, H do log:write("    " .. g[y] .. "   " .. r.gw[y] .. "\n") end
      log:flush()
    end
  end
end
log:write("== конец seed " .. seed .. "\n"); log:close()
