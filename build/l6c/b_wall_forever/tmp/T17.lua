-- T17: локальная доводка v17s (правый край за колонной E), старт фиксирован.
local vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(6, 2, 7, 5)
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 8, sortHid = true,
  grid = {
    "############",
    "#####.######",
    "#.......??##",
    "#.###.#.??##",
    "#.......??##",
    "######.#####",
    "######.#####",
    "######.#####",
    "############",
  },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { 3, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "upc", at = { 7, 3 }, ports = { up = "V", down = "V" } },
  },
  starts = {
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 }, { 8, 4 }, { 8, 3 } }, head = 5 },
  },
}
