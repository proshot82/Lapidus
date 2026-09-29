-- build/l2v2/wall.lua — ворота «замуровка» для build/l2e/k4.lua: по одной пустой клетке и по одному крюку,
-- затем жадно — всё мёртвое пространство разом. Мёртвое пространство = после замуровки то же кратчайшее решение
-- (та же последовательность ходов выигрывает, оптимум той же длины) и все абляции файла по-прежнему нерешаемы.
-- Печатает только метрики, без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local file = arg[1] or "build/l2e/k4.lua"
local base = dofile(file)

local function metrics(def)
  local ok, lvl = pcall(R.compile, def); if not ok then return nil end
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 3000000); if not G then return nil end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { solvable = false, n = n } end
  local good = SV.goodSet(G)
  local live, hid = 0, 0
  for i = 1, G.n do if G.flag[i] ~= 2 then
    if good[i] == 1 then live = live + 1 else
      local st = R.decode(lvl, G.keys[i])
      if not (def.visibleLoss and def.visibleLoss(lvl, st)) then hid = hid + 1 end end end end
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, G.pmove[x]); x = G.parent[x] end
  local r = { solvable = true, n = G.n, opt = G.depth[G.firstWin], live = live, hid = hid, pct = 100 * hid / math.max(1, hid + live), moves = path, lvl = lvl }
  SV.freeGraph(G); require("ffi").C.free(good)
  return r
end
local function replay(lvl, moves)
  local s = R.newState(lvl)
  for _, m in ipairs(moves) do
    s = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir); if not s or s.dead then return false end
  end
  return R.isWin(lvl, s)
end
local function ablOk(def)
  for _, a in ipairs(SV.ablations(def, { cap = 3000000 })) do if a.solvable ~= false then return false end end
  return true
end
local B = metrics(base)
print(string.format("БАЗА: ходов %d, состояний %d, живых %d, скрытых %d = %.1f %%", B.opt, B.n, B.live, B.hid, B.pct))

local function wallCell(d, x, y) d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
local function occupied(d, x, y)
  for _, o in ipairs(d.objects) do
    if o.at and o.at[1] == x and o.at[2] == y then return true end
    if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then return true end end end
  end
end
-- кандидаты: пустые клетки и крючья (кроме стартового top — без него нерешаем)
local cands = {}
for y = 1, #base.grid do for x = 1, #base.grid[1] do
  if base.grid[y]:sub(x, x) == "." and not occupied(base, x, y) then cands[#cands + 1] = { kind = "cell", x = x, y = y } end end end
for k, o in ipairs(base.objects) do if o.kind == "stub" then cands[#cands + 1] = { kind = "hook", tag = o.tag, x = o.at[1], y = o.at[2] } end end
local function apply(d, c)
  if c.kind == "cell" then wallCell(d, c.x, c.y) else
    local keep = {}; for _, o in ipairs(d.objects) do if not (o.at and o.at[1] == c.x and o.at[2] == c.y) then keep[#keep + 1] = o end end
    d.objects = keep; wallCell(d, c.x, c.y) end
end
local function name(c) return (c.kind == "hook" and ("крюк " .. c.tag) or "клетка") .. string.format("(%d,%d)", c.x, c.y) end
local function test(set)
  local d = SV.deepcopy(base)
  for _, c in ipairs(set) do apply(d, c) end
  local m = metrics(d)
  if not m or not m.solvable then return false, m end
  local same = m.opt == B.opt and replay(m.lvl, B.moves)
  return same and ablOk(d), m
end
print("по одному (мёртвое = решение и абляции те же):")
local dead = {}
for _, c in ipairs(cands) do
  local ok, m = test({ c })
  local s = not m and "невалиден" or (not m.solvable and "НЕРЕШАЕМ") or
    string.format("ходов %d, сост. %d, скрытых %.1f %%", m.opt, m.n, m.pct)
  print(string.format("  %-20s %s%s", name(c), s, ok and "   ← МЁРТВОЕ" or ""))
  if ok then dead[#dead + 1] = c end
end
-- жадно: сверху вниз и снизу вверх
for _, order in ipairs({ "как в списке", "обратный" }) do
  local list = {}
  for i = 1, #dead do list[i] = (order == "обратный") and dead[#dead + 1 - i] or dead[i] end
  local acc = {}
  for _, c in ipairs(list) do acc[#acc + 1] = c; if not test(acc) then acc[#acc] = nil end end
  local _, m = test(acc)
  local t = {}; for _, c in ipairs(acc) do t[#t + 1] = name(c) end
  print(string.format("жадно (%s): замуровано %d [%s] → ходов %d, сост. %d, живых %d, скрытых %d = %.1f %%",
    order, #acc, table.concat(t, " "), m.opt, m.n, m.live, m.hid, m.pct))
end
-- только крючья нижнего яруса и крюк «под коридором» разом
do
  local set = {}; for _, c in ipairs(cands) do if c.kind == "hook" and c.tag ~= "top" and c.tag ~= "row" then set[#set + 1] = c end end
  local ok, m = test(set)
  print(string.format("без всех крючьев нижнего яруса и «под коридором»: %s; ходов %d, сост. %d, скрытых %.1f %%; решение и абляции те же: %s",
    m.solvable and "решаем" or "нерешаем", m.opt or -1, m.n, m.pct or 0, tostring(ok)))
end
-- дно колодца: поднять пол на 1, 2, 3 ряда (клетки x=4..6)
for rows = 1, 3 do
  local set = {}; for y = 10 - rows, 9 do for x = 4, 6 do set[#set + 1] = { kind = "cell", x = x, y = y } end end
  local ok, m = test(set)
  print(string.format("пол колодца поднят на %d: %s; скрытых %s; решение и абляции те же: %s", rows,
    m and m.solvable and ("решаем за " .. m.opt) or "нерешаем", m and m.pct and string.format("%.1f %%", m.pct) or "—", tostring(ok)))
end
