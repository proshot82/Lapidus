-- b2: b1 с открытым правым карманом (поиск, где вообще возможна ловля).
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 8, flat = 8, name = "b2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "######.#####",
    "######.....#",
    "######.....#",
    "######.....#",
    "######.#####",
    "#####..#####",
    "######~#####",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 6, 7 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 8, 5 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 10, 5 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 11, 5 }, { 11, 4 } }, head = 2 },
  },
  ablations = { { name = "без угольника", remove = "elb" }, { name = "без муфты", remove = "cpl" } },
}
