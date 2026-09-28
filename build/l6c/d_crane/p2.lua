return {
  id = 6, flat = 6, name = "t", length = { 3, 5 }, pressure = 0,
  grid = {
    "########",
    "##.#.###",
    "##.#.###",
    "#......#",
    "#......#",
    "########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 3, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fitting", what = "nipple", tag = "n", at = { 4, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "c", at = { 6, 4 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 4 },
  },
}
