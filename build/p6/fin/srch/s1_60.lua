return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s1_60.lua", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "########......##",
    "########...#..##",
    "########......##",
    "########......##",
    "########......##",
    "########...#..##",
    "#.............##",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 13, 4 }, ports = { right = "V", left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 11, 5 }, ports = { right = "N", left = "N" } },
    { kind = "lapidus", cells = { {13,6},{12,6},{11,6} }, head = 1 },
  },
}
