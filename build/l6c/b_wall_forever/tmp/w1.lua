-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "####.####",
    "####.####",
    "####.####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { 3, 4 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 8, 4 }, { 7, 4 }, { 6, 4 }, { 5, 4 } }, head = 4 },
  },
  ablations = {  },
}
