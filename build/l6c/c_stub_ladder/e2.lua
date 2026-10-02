return {
  id = 6, name = "e2", length = { 3, 4 }, pressure = 0,
  grid = {
    "########",
    "####.###",
    "###...##",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "stub", at = { 4, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "A", at = { 6, 8 }, ports = { left = "V", up = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 7, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 7, 8 }, { 7, 7 }, { 7, 6 } }, head = 3 },
  },
}
