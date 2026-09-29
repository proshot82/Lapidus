-- build/l2v/abl.lua — абляции и контроли скептика: по одному крюку, по одной клетке, длина, резьбы. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local file = arg[1]
local function load() return dofile(file) end
local function run(def, filter)
  local ok, lvl = pcall(R.compile, def); if not ok then return "не компилируется" end
  local e = R.validate(lvl); if #e > 0 then return "невалиден" end
  local G = SV.explore(lvl, 3000000, filter)
  if not G then return "CAP" end
  local res
  if not G.firstWin then res = string.format("НЕРЕШАЕМ (%d сост.)", G.n) else
    local good = SV.goodSet(G)
    local live, dead, wash = 0, 0, 0
    for i = 1, G.n do if G.flag[i] == 2 then wash = wash + 1 elseif good[i] == 1 then live = live + 1 else
      local st = R.decode(lvl, G.keys[i])
      if not (def.visibleLoss and def.visibleLoss(lvl, st)) then dead = dead + 1 end end end
    local nw = 0; for i = 1, G.n do if G.flag[i] == 1 then nw = nw + 1 end end
    res = string.format("решаем за %d, сост. %d, скрытых %.0f %%, выигрышных %d", G.depth[G.firstWin], G.n, 100 * dead / math.max(1, dead + live), nw)
    require("ffi").C.free(good)
  end
  SV.freeGraph(G)
  return res
end
local base = load()
print("БАЗА: " .. run(base))
-- по одному крюку: замуровать; перевернуть резьбу
for k, o in ipairs(base.objects) do if o.kind == "stub" then
  local d = load(); local oo = d.objects[k]
  local r = d.grid[oo.at[2]]; d.grid[oo.at[2]] = r:sub(1, oo.at[1] - 1) .. "#" .. r:sub(oo.at[1] + 1)
  table.remove(d.objects, k)
  print(string.format("крюк y=%d замурован: %s", o.at[2], run(d)))
  local d2 = load(); for s, t in pairs(d2.objects[k].ports) do d2.objects[k].ports[s] = (t == "N") and "V" or "N" end
  print(string.format("крюк y=%d резьба наоборот: %s", o.at[2], run(d2)))
end end
-- все крючья наоборот (контроль автора)
do local d = load(); for _, o in ipairs(d.objects) do if o.kind == "stub" then for s, t in pairs(o.ports) do o.ports[s] = (t == "N") and "V" or "N" end end end
  print("все крючья наоборот: " .. run(d)) end
-- длина
for _, L in ipairs({ { 2, 3 }, { 3, 4 }, { 2, 5 }, { 2, 6 } }) do
  local d = load(); d.length = L
  -- тело старта может не влезать в диапазон
  local lap; for _, o in ipairs(d.objects) do if o.kind == "lapidus" then lap = o end end
  while #lap.cells > L[2] do table.remove(lap.cells, 1); lap.head = #lap.cells end
  print(string.format("длина %d–%d: %s", L[1], L[2], run(d)))
end
-- ноги вперёд из комнаты запрещены (контроль автора): фильтр = отрицание «головой вперёд» внутри комнаты
if base.ablations then for _, a in ipairs(base.ablations) do if a.filter then
  local f = a.filter
  local ctrl = function(lvl, st, ns)
    if f(lvl, st, ns) then
      -- ход разрешён фильтром «головой не падать»: это либо не выход из комнаты, либо выход ногами вперёд
      local W = lvl.W
      local function y(c) return math.floor((c - 1) / W) + 1 end
      local left = true; for _, c in ipairs(ns.body) do if y(c) <= 3 then left = false end end
      local inRoom = false; for _, c in ipairs(st.body) do if y(c) <= 3 and (c - 1) % W + 1 >= (W - 2) then inRoom = true end end
      if inRoom and left then return false end
    end
    return true
  end
  print("контроль «ноги вперёд из комнаты запрещены»: " .. run(base, ctrl))
end end end
-- по одной пустой клетке: замуровать
local same, change, unsol = {}, {}, {}
local b0 = run(base)
for y = 1, #base.grid do for x = 1, #base.grid[1] do
  if base.grid[y]:sub(x, x) == "." then
    local d = load()
    local occupied = false
    for _, o in ipairs(d.objects) do
      if o.at and o.at[1] == x and o.at[2] == y then occupied = true end
      if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then occupied = true end end end
    end
    if not occupied then
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      local r = run(d)
      local tag = string.format("(%d,%d)", x, y)
      if r:find("НЕРЕШАЕМ") or r == "невалиден" then unsol[#unsol + 1] = tag
      elseif r == b0 then same[#same + 1] = tag
      else change[#change + 1] = tag .. " " .. r end
    end
  end
end end
print("клетка → нерешаем: " .. #unsol .. "  " .. table.concat(unsol, " "))
print("клетка → ничего не меняет: " .. #same .. "  " .. table.concat(same, " "))
print("клетка → меняет метрики: " .. #change)
for _, s in ipairs(change) do print("   " .. s) end
