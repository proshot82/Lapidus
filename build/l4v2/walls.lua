-- build/l4v2/walls.lua — замуровать по одной пустой клетке и группы клеток; метрики каждого варианта (без ходов).
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local MT = dofile("build/l4v2/metrics.lua")
local file = arg[1] or "build/l4d/k40.lua"
local def0 = dofile(file)
local occ = {}
for _, o in ipairs(def0.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
local function wall(d, cells)
  for _, c in ipairs(cells) do local x, y = c[1], c[2]
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
  return d
end
print("исходный: " .. MT.fmt(MT.run(def0, true))); io.flush()
if arg[2] == "groups" then
  local groups = {
    { "верхний ряд x2-3", { { 2, 2 }, { 3, 2 } } },
    { "пол коридора x2-4 + x2-3 верх", { { 2, 5 }, { 3, 5 }, { 2, 6 }, { 3, 6 }, { 4, 6 } } },
    { "верхний ряд x5-8", { { 5, 2 }, { 6, 2 }, { 7, 2 }, { 8, 2 } } },
    { "антресоль слева x2-3 (оба ряда)", { { 2, 2 }, { 3, 2 }, { 2, 3 }, { 3, 3 } } },
    { "коридор слева x2 (оба ряда)", { { 2, 5 }, { 2, 6 } } },
    { "коридор слева x2-3 (оба ряда)", { { 2, 5 }, { 3, 5 }, { 2, 6 }, { 3, 6 } } },
    { "коридор слева x2-4 (оба ряда)", { { 2, 5 }, { 3, 5 }, { 4, 5 }, { 2, 6 }, { 3, 6 }, { 4, 6 } } },
    { "пол коридора x2-3 (нижний ряд)", { { 2, 6 }, { 3, 6 } } },
    { "верх коридора x2-4", { { 2, 5 }, { 3, 5 }, { 4, 5 } } },
    { "верх коридора x2-5", { { 2, 5 }, { 3, 5 }, { 4, 5 }, { 5, 5 } } },
    { "правый карман x9-10 (стр. 5-6)", { { 10, 5 }, { 10, 6 } } },
    { "верхний ряд кроме Лапидуса x2-3,5-8", { { 2, 2 }, { 3, 2 }, { 5, 2 }, { 6, 2 }, { 7, 2 }, { 8, 2 } } },
  }
  for _, g in ipairs(groups) do
    local d = wall(SV.deepcopy(def0), g[2])
    io.write(string.format("%-34s %s\n", g[1] .. ":", MT.fmt(MT.run(d, true)))); io.flush()
  end
  return
end
for y = 1, #def0.grid do
  for x = 1, #def0.grid[1] do
    if def0.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
      local d = wall(SV.deepcopy(def0), { { x, y } })
      io.write(string.format("стена (%d,%d): %s\n", x, y, MT.fmt(MT.run(d, true)))); io.flush()
    end
  end
end
