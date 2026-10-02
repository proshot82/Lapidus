-- n10: n7 на столбец короче (яма с 6-го, стояк 8, мойка 10), без слива
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "n10",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "#########.##",
    "#######.#.##",
    "#.........##",
    "#.........##",
    "#####.....##",
    "############",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 10, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 8, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 3 },
  },
  ablations = { },
}
