return {
  visibleLoss = dofile("build/l6b/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "#....#.###",
    "#........#",
    "###.##.#.#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3 },
  },
}
