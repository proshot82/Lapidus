return {
  id = 65, flat = 6, name = "b3", length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "##.....##",
    "##.##.###",
    "##..#.###",
    "#.....###",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 6, 3 }, { 6, 4 }, { 6, 5 } }, head = 3 },
  },
}
