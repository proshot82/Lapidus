return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s13_161.lua", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "########.......#",
    "########.......#",
    "########..#....#",
    "########.......#",
    "########.......#",
    "########.......#",
    "#..............#",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 13, 8 }, ports = { right = "V", left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 12, 5 }, ports = { right = "N", left = "N" } },
    { kind = "lapidus", cells = { {12,9},{13,9},{14,9} }, head = 1 },
  },
}
