return {
  id = 10, flat = 10, name = "h3", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "##############",
    "#######......#",
    "#######......#",
    "#######.#.#..#",
    "#######......#",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 10, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 12, 2 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 10, 3 }, { 11, 3 }, { 12, 3 } }, head = 1 },
  },
}
