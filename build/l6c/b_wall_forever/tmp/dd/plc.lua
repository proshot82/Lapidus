-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.none,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "#...#.###",
    "#.......#",
    "#.##.#.##",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N", up = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "plug", at = { 2, 2 }, tag = "pp", ports = { down = "V" } },
    { kind = "fitting", what = "nipple", at = { 5, 4 }, tag = "upn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 6, 5 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 5, 5 }, { 4, 5 }, { 3, 5 } }, head = 3 },
  },
  ablations = {  },
}
