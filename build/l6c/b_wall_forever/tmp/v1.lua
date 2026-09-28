-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "#######",
    "###.###",
    "###.###",
    "#.....#",
    "#.#.#.#",
    "#.....#",
    "###.###",
    "###.###",
    "#######",
  },
  objects = {
    { kind = "source", at = { 4, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", at = { 3, 4 }, tag = "pc", ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", at = { 5, 4 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 6 }, { 4, 6 }, { 5, 6 }, { 6, 6 } }, head = 4 },
  },
  ablations = {  },
}
