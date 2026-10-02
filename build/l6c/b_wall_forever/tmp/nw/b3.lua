-- 
local V = { vis = dofile("build/l6c/b_wall_forever/vis_nw.lua")(4, 4, 2) }
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#.........#",
    "#.#.##.####",
    "#........##",
    "###.#######",
    "###########",
  },
  objects = {
    { kind = "source", at = { 10, 2 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 4, 5 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", at = { 3, 2 }, tag = "nip", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 6, 2 }, tag = "cpl", ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 4 }, { 6, 4 }, { 5, 4 } }, head = 3 },
  },
  ablations = {  },
}
