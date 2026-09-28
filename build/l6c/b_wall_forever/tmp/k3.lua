-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "####.####",
    "##...####",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", at = { 5, 3 }, tag = "upn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 4, 4 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 4 }, { 7, 4 }, { 6, 4 }, { 5, 4 } }, head = 4 },
  },
  ablations = {  },
}
