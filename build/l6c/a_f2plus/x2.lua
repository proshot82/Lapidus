-- x2: проба: f2, но Лапидус ногами к стояку (голова у муфты)
return {
  visibleLoss = dofile("build/l6c/a_f2plus/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "##..#.###",
    "#.......#",
    "##.##.#.#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3,5 }, { 4,5 }, { 5,5 } }, head = 3 },
  },
  ablations = dofile("build/l6c/a_f2plus/abl.lua"),
}
