-- f1: угольник — подставка под ниппелем; выбить его головой в жёлоб (прикипит к стояку), ниппель остаётся на голове
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 8, flat = 8, name = "f1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "####.####",
    "####.####",
    "####....#",
    "###.....#",
    "###.#...#",
    "##..#####",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "A", at = { 5, 5 }, ports = { left = "V", up = "V" } },
    { kind = "source", at = { 3, 7 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 7, 5 }, { 8, 5 } }, head = 3 },
  },
  ablations = { },
}
