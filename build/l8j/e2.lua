-- e2: мыло под муфтой, выбить ногами влево в слив; угольник падает в столбец 6 на стояк
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "e2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "####.######",
    "####.######",
    "####......#",
    "#.........#",
    "###.#.#####",
    "###.#..####",
    "###~#######",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "fitting", what = "elbow", tag = "A", at = { 7, 5 }, ports = { up = "N", right = "V" } },
    { kind = "source", at = { 7, 7 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 9, 5 }, { 10, 5 } }, head = 2 },
  },
  ablations = { },
}
