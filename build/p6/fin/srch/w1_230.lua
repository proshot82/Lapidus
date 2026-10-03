return {
  id = 10, flat = 10, name = "srch/w1_230.lua", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "##############",
    "##############",
    "#######......#",
    "#######.#....#",
    "#######.....##",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 10, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 12, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 12, 4 }, { 11, 4 }, { 10, 4 } }, head = 1 },
  },
}
