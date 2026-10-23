return {
  id = 64, flat = 6, name = "b2", length = { 3, 6 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "##.....##",
    "##.##.###",
    "##..#.###",
    "#......##",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { left = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 5, 2 }, { 6, 2 }, { 6, 3 } }, head = 3 },
  },
}
