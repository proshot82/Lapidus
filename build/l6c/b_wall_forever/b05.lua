-- b05 (из черновика tmp)
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "####.#####",
    "####.##.##",
    "####.##.##",
    "#........#",
    "##.##.####",
    "##.##.####",
    "##.#######",
    "##########",
  },
  objects = {
    { kind = "source", at = { 3, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", at = { 5, 4 }, tag = "upn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 3, 5 }, tag = "pc", ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 6, 5 }, { 5, 5 }, { 4, 5 } }, head = 4 },
  },
  ablations = {  },
}
