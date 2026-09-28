-- 
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "#........#",
    "#.####.#.#",
    "#.#....#.#",
    "#.####.#.#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { up = "N", right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "plug", at = { 3, 2 }, tag = "pp", ports = { down = "V" } },
    { kind = "fitting", what = "nipple", at = { 6, 4 }, tag = "pn", ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", at = { 3, 6 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 7, 6 }, { 6, 6 }, { 5, 6 } }, head = 4 },
  },
  ablations = {  },
}
