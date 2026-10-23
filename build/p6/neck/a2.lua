return {
  id = 62, flat = 6, name = "a2", length = { 3, 4 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "##.....##",
    "##.###.##",
    "##..##.##",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "toilet", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 2 }, ports = { left = "V", right = "N" } },
    { kind = "lapidus", cells = { { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 3 },
  },
}
