return {
  id = 7, name = "m1", length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.#.....#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 4, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 2 }, ports = { left = "V" } },
    { kind = "fitting", tag = "a", at = { 3, 6 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", tag = "b", at = { 6, 7 }, ports = { down = "V", up = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 2, 6 } }, head = 2 },
  },
}
