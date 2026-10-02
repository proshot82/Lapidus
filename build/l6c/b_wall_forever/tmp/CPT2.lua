-- CPT2: доводка ядра v2 (колонна-проход без правого кольца): стены «?» по краям, три старта.
local vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(5, 2, 6, 5)
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 11, sortHid = true, minHid = 30,
  grid = {
    "###########",
    "####.######",
    "#??.....??#",
    "#?##.#.??##",
    "#??.....??#",
    "#####.#####",
    "#####.#####",
    "#####.#####",
    "###########",
  },
  objects = {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { 4, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "upc", at = { 6, 3 }, ports = { up = "V", down = "V" } },
  },
  starts = {
    { cells = { { 7, 5 }, { 7, 4 }, { 7, 3 } }, head = 3 },
    { cells = { { 6, 5 }, { 7, 5 }, { 7, 4 } }, head = 3 },
    { cells = { { 7, 5 }, { 7, 4 }, { 7, 3 }, { 8, 3 } }, head = 4 },
  },
}
