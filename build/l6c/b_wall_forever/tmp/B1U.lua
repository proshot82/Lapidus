-- B1U: ядро b01, доводка стен (клетки «?») ради узкого живого коридора
local V = dofile("build/l6c/b_wall_forever/b01.lua")
local function objs(cx, cy, nx, ny)
  return {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "upc", at = { cx, cy }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { nx, ny }, ports = { up = "N", down = "N" } },
  }
end
return {
  length = { 3, 5 }, visibleLoss = V.visibleLoss, maxQ = 10, minHid = 25,
  grid = {
    "##########",
    "#??#.#??##",
    "#?.......#",
    "#.#?.#?.##",
    "#?.......#",
    "#####.####",
    "#####.####",
    "#####.####",
    "##########",
  },
  objectSets = { objs(4, 3, 7, 5), objs(3, 3, 7, 5) },
  starts = {
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3 },
    { cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 1 },
    { cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 3 },
    { cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 4 },
  },
}
