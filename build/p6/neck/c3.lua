return {
  id = 76, flat = 6, name = "c3", length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "########",
    "##.....#",
    "##.##.##",
    "##....##",
    "#...####",
    "########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 4, 4 }, { 5, 4 } }, head = 1 },
  },
}
