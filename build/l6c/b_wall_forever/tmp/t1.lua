return {
  id = 6, flat = 6, name = "t", length = { 3, 5 }, pressure = 0,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#...##..#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 8, 8 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 3, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 8 }, { 4, 8 }, { 5, 8 } }, head = 1 },
  },
}
