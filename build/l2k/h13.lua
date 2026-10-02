return {
  visibleLoss = dofile("build/l2k/vis.lua"),
  id = 2, flat = 2, name = "h13",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  grid = {
    "########",
    "##....##",
    "##....##",
    "##....##",
    "##....##",
    "#...#.##",
    "##.....#",
    "##....##",
    "#~~~~~~#",
  },
  objects = {
    { kind = "stub", tag = "hook", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "fixture", what = "toilet", at = { 6, 8 }, ports = { left = "N" } },
    { kind = "source", at = { 7, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 4 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 5, 5 }, { 4, 5 }, { 3, 5 } }, head = 4 },
  },
  ablations = dofile("build/l2k/abl.lua")({ "hook" }, { "cpl" }),
}
