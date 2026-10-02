return {
  visibleLoss = dofile("build/l2k/vis.lua"),
  id = 2, flat = 2, name = "h6",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  grid = {
    "########",
    "#......#",
    "##.#..##",
    "##.....#",
    "#...#..#",
    "##.....#",
    "#....#.#",
    "#~~~~~~#",
  },
  objects = {
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "toilet", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 2 }, { 6, 2 } }, head = 2 },
  },
  ablations = dofile("build/l2k/abl.lua")({ "hook" }, { "cpl" }),
}
