-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#.........#",
    "####.###.##",
    "###.......#",
    "####~~~~~##",
    "###########",
  },
  objects = {
    { kind = "source", at = { 10, 4 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 4, 4 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", at = { 4, 2 }, tag = "pn", ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", at = { 8, 2 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 5, 2 }, { 6, 2 }, { 7, 2 } }, head = 3 },
  },
  ablations = {  },
}
