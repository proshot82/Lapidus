return {
  id = 10, flat = 10, name = "e1", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "##############",
    "#######......#",
    "#######......#",
    "#######.#....#",
    "#######.....##",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 13, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 13, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 11, 6 }, { 12, 6 }, { 13, 6 } }, head = 1 },
  },
}
