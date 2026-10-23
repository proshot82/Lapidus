-- r10: без мыла, муфта с начала на голове у спуска
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  mustLift = { "B" },
  id = 8, flat = 8, name = "r10",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "########.#",
    "######.#.#",
    "##.......#",
    "##.......#",
    "#####...##",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 9, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 6, 4 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3 },
  },
  ablations = { },
}
