-- build/l5d/wall.lua файл.lua — «замуровка»: по одной замуровывает каждую пустую клетку; клетка — мёртвое
-- пространство, если без неё число ходов, решаемость и абляции не меняются. Затем замуровывает все мёртвые клетки
-- разом (жадно, с проверкой) и печатает долю скрытых до и после. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local path = arg[1]
local function load() local d = dofile(path); return d end
local function metrics(d, abl)
  local ok, lvl = pcall(R.compile, d)
  if not ok or #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 3000000)
  if not G or not G.firstWin then if G then SV.freeGraph(G) end return { solvable = false } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, d, good)
  local m = V.measure(G, good, VL.newbie)
  local r = { solvable = true, opt = m.opt, hid = m.hiddenPct, n = G.n, smart = m.smart }
  SV.freeGraph(G); require("ffi").C.free(good)
  if abl then
    local a = SV.ablations(d, { cap = 3000000 })
    local s = {}
    for _, x in ipairs(a) do s[#s+1] = tostring(x.solvable) end
    r.abl = table.concat(s, ",")
  end
  return r
end
local base = load()
local b = metrics(base, true)
print(string.format("база: ходов %d, состояний %d, скрытых %.1f %%, обезьяна %.3f, абляции %s", b.opt, b.n, b.hid, b.smart, b.abl))
local occ = {}
for _, o in ipairs(base.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
local dead = {}
for y = 1, #base.grid do for x = 1, #base.grid[y] do
  if base.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
    local d = load()
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
    local r = metrics(d, true)
    local isDead = r and r.solvable and r.opt == b.opt and r.abl == b.abl
    print(string.format("  (%d,%d): %s", x, y, r and (r.solvable and string.format("ходов %d скрытых %.1f %% абл %s%s", r.opt, r.hid, r.abl, isDead and "  → мёртвая" or "") or "НЕРЕШАЕМ") or "некорректно"))
    if isDead then dead[#dead+1] = { x, y } end
  end
end end
-- жадно: замуровать все мёртвые, пока решение и абляции не меняются
local cur = load()
local walled = {}
for _, c in ipairs(dead) do
  local d = load()
  for _, w in ipairs(walled) do d.grid[w[2]] = d.grid[w[2]]:sub(1, w[1] - 1) .. "#" .. d.grid[w[2]]:sub(w[1] + 1) end
  d.grid[c[2]] = d.grid[c[2]]:sub(1, c[1] - 1) .. "#" .. d.grid[c[2]]:sub(c[1] + 1)
  local r = metrics(d, true)
  if r and r.solvable and r.opt == b.opt and r.abl == b.abl then walled[#walled+1] = c; cur = d end
end
local r = metrics(cur, false)
local t = {} for _, w in ipairs(walled) do t[#t+1] = "(" .. w[1] .. "," .. w[2] .. ")" end
print(string.format("замуровано %d: %s", #walled, table.concat(t, " ")))
print(string.format("после замуровки: ходов %d, состояний %d, скрытых %.1f %%, обезьяна %.3f", r.opt, r.n, r.hid, r.smart))
for _, row in ipairs(cur.grid) do print("   " .. row) end
