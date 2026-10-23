return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s14_1.lua", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "################",
    "################",
    "################",
    "########.......#",
    "########.....#.#",
    "########..#..#.#",
    "#..............#",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 11, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 6 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { {12,6},{13,6},{14,6} }, head = 1 },
  },
}
