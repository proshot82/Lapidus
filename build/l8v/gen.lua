-- build/l8v/gen.lua seed count [файл-вывода] — скептик кв. 8: случайная разведка семейства «два выстрела с двух якорей»:
-- Q в левой стене (В, якорь ног), X справа (вверх В с угольником-переходником вниз Н/влево Н, или влево В с ниппелем Н,Н),
-- пробка (влево Н) в Q, переходник в X — голова вешается на переходник (M1), ноги в ванну. Печатаются только раскладки,
-- где уровень решаем и абляция «брандспойт не бьёт» нерешаема; для них — ходов, скрытых %, двери по половинам, прогулка.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local seed, count = tonumber(arg[1] or 1), tonumber(arg[2] or 200)
math.randomseed(seed)
local function rnd(a, b) return math.random(a, b) end
local function pick(t) return t[rnd(1, #t)] end
local function mk()
  local W, H = 13, 9
  local rows = {}
  for y = 1, H do
    local r = {}
    for x = 1, W do r[x] = (x == 1 or x == W or y == 1 or y == H or x == 2) and "#" or "." end
    rows[y] = r
  end
  local used = {}
  local function free(x, y) return rows[y][x] == "." and not used[x .. "," .. y] end
  local yq = rnd(3, 7)
  rows[yq][2] = "."
  used["2," .. yq] = true
  local objs = { { kind = "source", at = { 2, yq }, ports = { right = "V" } } }
  -- X и переходник
  local xkind = pick({ "up", "left" })
  local xx, xy
  if xkind == "up" then
    xx, xy = rnd(6, 12), rnd(4, 8)
    objs[#objs + 1] = { kind = "source", at = { xx, xy }, ports = { up = "V" } }
    objs[#objs + 1] = { kind = "fitting", what = "elbow", tag = "adp", at = { 0, 0 }, ports = pick({ { down = "N", left = "N" }, { down = "N", right = "N" } }) }
  else
    xx, xy = rnd(7, 12), rnd(3, 8)
    objs[#objs + 1] = { kind = "source", at = { xx, xy }, ports = { left = "V" } }
    objs[#objs + 1] = { kind = "fitting", what = "nipple", tag = "adp", at = { 0, 0 }, ports = { left = "N", right = "N" } }
  end
  used[xx .. "," .. xy] = true
  -- стенки под X, если он не у пола (чтобы выглядел стоящим) — необязательно; случайно
  if xy < 8 and rnd(1, 2) == 1 then for y = xy + 1, 8 do rows[y][xx] = "#" end end
  -- пробка и переходник на полках
  local function shelf(tag)
    for _ = 1, 50 do
      local x, y = rnd(3, 12), rnd(2, 7)
      if free(x, y) and free(x, y + 1) and not (y + 1 == yq and x == 3) then
        rows[y + 1][x] = "#"; used[x .. "," .. y] = true
        return x, y
      end
    end
  end
  local px, py = shelf()
  if not px then return nil end
  objs[#objs + 1] = { kind = "fitting", what = "plug", tag = "plug", at = { px, py }, ports = { left = "N" } }
  local ax, ay = shelf()
  if not ax then return nil end
  for _, o in ipairs(objs) do if o.tag == "adp" then o.at = { ax, ay } end end
  -- ванна
  local bx, by, bports
  if rnd(1, 2) == 1 then bx, by, bports = rnd(3, 12), 8, { up = "V" } else bx, by, bports = 12, rnd(3, 7), { left = "V" } end
  if not free(bx, by) then return nil end
  used[bx .. "," .. by] = true
  objs[#objs + 1] = { kind = "fixture", what = "bath", at = { bx, by }, ports = bports }
  -- случайные стенки
  for _ = 1, rnd(0, 3) do local x, y = rnd(3, 12), rnd(2, 7); if free(x, y) then rows[y][x] = "#" end end
  -- Лапидус на полу
  local lx
  for _ = 1, 30 do lx = rnd(3, 11); if free(lx, 8) and free(lx + 1, 8) then break end lx = nil end
  if not lx then return nil end
  objs[#objs + 1] = { kind = "lapidus", cells = { { lx, 8 }, { lx + 1, 8 } }, head = 2 }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(rows[y]) end
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = 2, grid = grid, objects = objs,
    ablations = { { name = "брандспойт не бьёт", filter = F.noHose } } }
end
local function eval(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 300000)
  if not G or not G.firstWin then if G then SV.freeGraph(G) end return nil end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local ES, E = G.eStart.p, G.edges.p
  local h1, h2 = 0, 0
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = ES[s - 1], ES[s] - 1 do if m.hidden[E[e]] then c = c + 1 end end
    if c > 0 then if (k - 1) < (#path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end end
  end
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  local streak, maxStreak = 0, 0
  for i = 1, #path - 1 do if objs(path[i]) ~= objs(path[i+1]) then streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end end
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local n = G.n
  SV.freeGraph(G); require("ffi").C.free(good)
  local ab = SV.ablations(def, { cap = 300000 })
  if ab[1].solvable ~= false then return nil end
  return string.format("ходов %2d n=%6d win=%d скрытых %5.1f%% обез %.2f глуб %2d двери %d/%d прогулка %d", m.opt, n, nwin, m.hiddenPct, m.smart, m.maxDeep, h1, h2, maxStreak)
end
local out = arg[3] and assert(io.open(arg[3], "a")) or io.stdout
local found = 0
for i = 1, count do
  local def = mk()
  if def then
    local r = eval(def)
    if r then
      found = found + 1
      out:write(string.format("--- seed %d #%d: %s\n", seed, i, r))
      for _, row in ipairs(def.grid) do out:write("  " .. row .. "\n") end
      for _, o in ipairs(def.objects) do
        if o.kind == "lapidus" then out:write(string.format("  lapidus %d,%d-%d,%d head=%d\n", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2], o.head))
        else local ps = {}; for k, v in pairs(o.ports) do ps[#ps+1] = k .. "=" .. v end; table.sort(ps)
          out:write(string.format("  %s %s at %d,%d ports %s\n", o.kind, o.what or "", o.at[1], o.at[2], table.concat(ps, ","))) end
      end
      out:flush()
    end
  end
end
out:write(string.format("=== seed %d: проверено %d, найдено %d (решаемых с обязательным брандспойтом)\n", seed, count, found))
out:close()
