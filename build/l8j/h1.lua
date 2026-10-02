-- h1: башенка мыло/угольник/ниппель; жёлоб слева: мыло в слив, угольник прикипает выше слива, ноги сверху в угольник
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "h1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "####.#####",
    "####.#####",
    "####.....#",
    "###......#",
    "###......#",
    "##..######",
    "###~######",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "A", at = { 5, 5 }, ports = { left = "V", up = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 6 } },
    { kind = "source", at = { 3, 7 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 7, 5 }, { 8, 5 } }, head = 3 },
  },
  ablations = { },
}
