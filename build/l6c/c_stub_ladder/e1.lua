return {
  id = 6, name = "e1", length = { 3, 4 }, pressure = 0,
  grid = {
    "########",
    "####.###",
    "####.###",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "stub", at = { 4, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "A", at = { 7, 8 }, ports = { left = "V", up = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 2, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 8 }, { 3, 8 }, { 3, 7 } }, head = 1 },
  },
}
