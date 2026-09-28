-- 
local V = { vis = dofile("build/l6c/b_wall_forever/tmp/shvis.lua")(5, 3, 5) }
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "####.####",
    "#.......#",
    "#.##.##.#",
    "#.......#",
    "####...##",
    "####.####",
    "####.####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", at = { 7, 3 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 7, 5 }, tag = "upc", ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 4, 3 }, { 3, 3 }, { 2, 3 } }, head = 3 },
  },
  ablations = {  },
}
