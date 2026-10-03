return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s11_177.lua", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "################",
    "########......##",
    "########......##",
    "########......##",
    "########......##",
    "########...#.###",
    "#.............##",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 11, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { {12,4},{13,4},{14,4} }, head = 1 },
  },
}
