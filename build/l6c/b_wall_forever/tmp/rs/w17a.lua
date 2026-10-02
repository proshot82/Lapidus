-- 
local V = { vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(6, 2, 7, 5) }
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#####.#####",
    "#.......###",
    "#.###.#.###",
    "#........##",
    "######.####",
    "######.####",
    "######.####",
    "###########",
  },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", at = { 3, 3 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 7, 3 }, tag = "upc", ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 7, 5 }, { 8, 5 }, { 8, 4 }, { 8, 3 } }, head = 5 },
  },
  ablations = {  },
}
