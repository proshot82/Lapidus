return {
  id = 10, flat = 10, name = "srch/w2_19.lua", length = { 2, 6 }, pressure = 0, tile = "mustard",
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
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 10, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 12, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 12, 5 }, { 11, 5 }, { 10, 5 } }, head = 1 },
  },
}
