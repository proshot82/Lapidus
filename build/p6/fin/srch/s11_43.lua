return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s11_43.lua", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "################",
    "################",
    "################",
    "########......##",
    "########......##",
    "########..#.#.##",
    "#.............##",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 13, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 11, 6 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { {14,9},{13,9},{12,9} }, head = 1 },
  },
}
