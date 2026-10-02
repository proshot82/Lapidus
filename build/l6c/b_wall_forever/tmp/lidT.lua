-- шаблон: муфта-крышка над ямой стояка, ниппель на спине под колонкой; разворот только под крышкой
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  length = { 3, 5 }, visibleLoss = V.vis, maxQ = 10,
  grid = {
    "##########",
    "######.###",
    "#??###.?##",
    "#??#.#.?##",
    "#........#",
    "#??#.#####",
    "####.#####",
    "####.#####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 5, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "upn", at = { 7, 4 }, ports = { up = "N", down = "N" } },
  },
  starts = {
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 1 },
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 }, { 9, 5 } }, head = 1 },
  },
}
