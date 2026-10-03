return {
  id = 61, flat = 6, name = "a1", length = { 3, 4 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "##......##",
    "##..##.###",
    "##..##.###",
    "#.......##",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "toilet", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 5 }, ports = { left = "V", right = "N" } },
    { kind = "lapidus", cells = { { 7, 3 }, { 7, 4 }, { 7, 5 } }, head = 1 },
  },
}
