-- b06 (из черновика tmp)
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "##......#",
    "##.##...#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", at = { 4, 4 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "elbow", at = { 6, 4 }, tag = "pe", ports = { up = "N", left = "N" } },
    { kind = "lapidus", cells = { { 3, 2 }, { 4, 2 }, { 5, 2 }, { 6, 2 } }, head = 4 },
  },
  ablations = {  },
}
