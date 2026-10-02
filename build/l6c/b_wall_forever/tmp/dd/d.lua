-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.none,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "#########",
    "##......#",
    "##.#.#.##",
    "#......##",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", at = { 6, 3 }, tag = "pn", ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", at = { 4, 5 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 6, 5 }, { 5, 5 } }, head = 3 },
  },
  ablations = {  },
}
