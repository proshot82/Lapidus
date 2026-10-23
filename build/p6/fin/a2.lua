return {
  id = 10, flat = 10, name = "a2", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "#..............#",
    "#..............#",
    "#..............#",
    "#..............#",
    "#............###",
    "#..............#",
    "########.......#",
    "#..............#",
    "########~~######",
  },
  objects = {
    { kind = "fitting", what = "nipple", tag = "nip", at = { 14, 5 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 12, 8 }, ports = { left = "V", right = "V" } },
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 12, 9 }, { 13, 9 }, { 14, 9 } }, head = 1 },
  },
}
