-- n12: проба
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "n12",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#############",
    "##########.##",
    "########.#.##",
    "#..........##",
    "#...........#",
    "#####......##",
    "#############",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 11, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 9, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 6, 5 } },
    { kind = "lapidus", cells = { { 4, 5 }, { 3, 5 }, { 2, 5 } }, head = 3 },
  },
  ablations = { },
}
