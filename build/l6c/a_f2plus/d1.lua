-- d1: две двери: гнёзда стояка и колонки над коридором, детали падают сквозь чужое гнездо
return {
  visibleLoss = dofile("build/l6c/a_f2plus/vis2.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "###.#.###",
    "#.......#",
    "#.#.#.#.#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 4, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3,5 }, { 4,5 }, { 5,5 } }, head = 3 },
  },
  ablations = dofile("build/l6c/a_f2plus/abl.lua"),
}
