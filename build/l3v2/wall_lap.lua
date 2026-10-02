-- build/l3v2/wall_lap.lua — замуровка клеток под стартовым Лапидусом (wall.lua их пропускает):
-- стартовое тело укорачивается/сдвигается, клетка становится стеной; метрики и абляции.
local L = dofile("build/l7v_g/lib.lua")
local path = "build/l3d/s8.lua"
local function var(name, cellWall, body, head)
  local d = dofile(path)
  for _, c in ipairs(cellWall) do
    local x, y = c[1], c[2]
    d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
  end
  for _, o in ipairs(d.objects) do if o.kind == "lapidus" then o.cells = body; o.head = head end end
  print(name .. ": " .. L.fmt(L.metrics(d, { abl = true, strict = true })))
  for _, p in ipairs({ 5 }) do print("   карман " .. p .. ": " .. L.fmt(L.metrics(d, { pocket = p }))) end
end
var("контроль: тело длины 3 без (2,6), клетка открыта", {}, { { 4, 7 }, { 4, 6 }, { 3, 6 } }, 3)
var("(2,6) стена, тело длины 3", { { 2, 6 } }, { { 4, 7 }, { 4, 6 }, { 3, 6 } }, 3)
var("(2,6) стена, голова на (3,5)", { { 2, 6 } }, { { 4, 7 }, { 4, 6 }, { 3, 6 }, { 3, 5 } }, 4)
var("контроль: голова на (3,5), (2,6) открыта", {}, { { 4, 7 }, { 4, 6 }, { 3, 6 }, { 3, 5 } }, 4)
var("(4,7) стена, тело (4,6)(3,6)(2,6)", { { 4, 7 } }, { { 4, 6 }, { 3, 6 }, { 2, 6 } }, 3)
