-- h2: ядро g1 + колодец (6,4..6): в колодец входить ногами вперёд
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "h2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "####.#####",
    "####.#...#",
    "####.....#",
    "###...####",
    "##....####",
    "###.######",
    "###~######",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 5, 5 }, ports = { left = "V", right = "V" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "porcelain", tag = "soap", at = { 5, 6 } },
    { kind = "lapidus", cells = { { 8, 3 }, { 9, 3 }, { 9, 4 } }, head = 3 },
  },
  ablations = { },
}
