return {
  id = 6, name = "e3", length = { 3, 4 }, pressure = 0,
  grid = {
    "########",
    "####.###",
    "##.....#",
    "##.....#",
    "#......#",
    "#..#...#",
    "#..#...#",
    "#.....##",
    "####~###",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 2, 8 }, ports = { up = "V" } },
    { kind = "stub", at = { 4, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 7, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 7, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 6, 6 }, { 6, 7 } }, head = 1 },
  },
}
