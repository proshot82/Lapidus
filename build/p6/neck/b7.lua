return {
  id = 71, flat = 6, name = "b7", length = { 4, 6 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "##......##",
    "##.###.###",
    "##...#.###",
    "#......###",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 2 }, { 7, 3 }, { 7, 4 }, { 7, 5 } }, head = 4 },
  },
}
