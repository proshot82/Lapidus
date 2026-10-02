-- n9_657585: муфту поймать спиной под гнездом, ниппель задвинуть головой справа
return {
  visibleLoss = dofile("build/l6c/a_f2plus/vis2.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
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
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 6,5 }, { 7,5 }, { 8,5 } }, head = 3 },
  },
  ablations = dofile("build/l6c/a_f2plus/abl.lua"),
}
