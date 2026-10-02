-- b07 (из черновика tmp)
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.none,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "####.#####",
    "#.....####",
    "#.##.#.###",
    "#.......##",
    "######.###",
    "######.###",
    "######.###",
    "##########",
  },
  objects = {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", at = { 4, 3 }, tag = "upc", ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", at = { 7, 4 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 8, 5 }, { 7, 5 }, { 6, 5 }, { 5, 5 } }, head = 4 },
  },
  ablations = {  },
}
