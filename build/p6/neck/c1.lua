return {
  id = 68, flat = 6, name = "c1", length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "########",
    "##....##",
    "##.#.###",
    "##...###",
    "#...####",
    "########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { left = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 4, 4 }, { 5, 4 } }, head = 1 },
  },
}
