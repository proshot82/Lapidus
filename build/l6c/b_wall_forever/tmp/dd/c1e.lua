-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#....#.####",
    "#........##",
    "##.###.#.##",
    "#........##",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", at = { 8, 3 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 7, 5 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 5, 5 }, { 4, 5 } }, head = 3 },
  },
  ablations = {  },
}
