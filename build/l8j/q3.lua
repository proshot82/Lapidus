-- q3: q2 со стартом длины 3 (проба)
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "q3",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "########.#",
    "######.#.#",
    "###......#",
    "#........#",
    "####.....#",
    "####.#####",
    "####~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 9, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 4, 5 }, { 3, 5 }, { 2, 5 } }, head = 3 },
  },
  ablations = { },
}
