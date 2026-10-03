return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s11_192.lua", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "################",
    "################",
    "################",
    "########......##",
    "########......##",
    "########....#.##",
    "#.............##",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 13, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 11, 7 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { {10,6},{11,6},{12,6} }, head = 1 },
  },
}
