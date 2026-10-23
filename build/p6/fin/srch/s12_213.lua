return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s12_213.lua", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "################",
    "################",
    "################",
    "########.......#",
    "########....#..#",
    "########.......#",
    "#..............#",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 11, 7 }, ports = { right = "V", left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 7 }, ports = { right = "N", left = "N" } },
    { kind = "lapidus", cells = { {13,8},{14,8},{15,8} }, head = 1 },
  },
}
