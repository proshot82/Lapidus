-- n8L36: n8, длина 3, 6
return {
  visibleLoss = dofile("build/l6c/a_f2plus/vis2.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "#####.###",
    "###.....#",
    "###.#.#.#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4,5 }, { 4,4 }, { 4,3 } }, head = 3 },
  },
  ablations = dofile("build/l6c/a_f2plus/abl.lua"),
}
