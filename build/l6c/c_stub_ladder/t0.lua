return {
  id = 6, name = "t0", length = { 3, 5 }, pressure = 0,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { down = "V" } },
    { kind = "stub", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 4, 7 }, { 5, 7 }, { 6, 7 } }, head = 3 },
  },
}
