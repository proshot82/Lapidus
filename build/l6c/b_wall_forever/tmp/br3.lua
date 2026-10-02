-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.none,
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#.........#",
    "###.###.###",
    "##.......##",
    "####...####",
    "####~~~####",
  },
  objects = {
    { kind = "source", at = { 9, 4 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 3, 4 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", at = { 4, 2 }, tag = "pn", ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", at = { 7, 2 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 4, 3 }, { 4, 4 }, { 5, 4 }, { 6, 4 } }, head = 4 },
  },
  ablations = {  },
}
