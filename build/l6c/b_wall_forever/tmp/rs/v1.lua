-- 
local V = { vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(5, 2, 6, 5) }
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "####.#####",
    "#.......##",
    "#.##.#.###",
    "#........#",
    "#####.####",
    "#####.####",
    "#####.####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", at = { 4, 3 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 6, 3 }, tag = "upc", ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 7, 4 }, { 7, 3 } }, head = 3 },
  },
  ablations = {  },
}
