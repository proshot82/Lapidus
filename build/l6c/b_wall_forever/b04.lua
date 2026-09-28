-- b04 (из черновика tmp)
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  visibleLoss = V.none,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "###########",
    "#.........#",
    "##.##.##.##",
    "#.........#",
    "##~~~~~~~##",
  },
  objects = {
    { kind = "source", at = { 10, 5 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", at = { 4, 3 }, tag = "pn", ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", at = { 8, 3 }, tag = "pc", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 5, 3 }, { 6, 3 }, { 7, 3 } }, head = 3 },
  },
  ablations = {  },
}
