-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "##.#.####",
    "#.......#",
    "##.#.####",
    "##.#.####",
    "##.#.####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 3, 6 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", at = { 3, 2 }, tag = "pc", ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", at = { 5, 2 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 5, 3 }, { 4, 3 }, { 3, 3 } }, head = 3 },
  },
  ablations = {  },
}
