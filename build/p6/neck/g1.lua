return {
  id = 79, flat = 6, name = "g1", length = { 4, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "###.....#",
    "###.##.##",
    "##.....##",
    "##...####",
    "###.#####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 4, 6 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 2 }, ports = { down = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 6, 4 }, { 7, 4 }, { 7, 3 }, { 7, 2 } }, head = 1 },
  },
}
