return {
  id = 10, flat = 10, name = "build/p6/fin/srch/s13_243.lua", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "################",
    "########......##",
    "########......##",
    "########......##",
    "########......##",
    "########......##",
    "########......##",
    "#.............##",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", what = "", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 11, 5 }, ports = { right = "V", left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 11, 6 }, ports = { right = "N", left = "N" } },
    { kind = "lapidus", cells = { {13,3},{12,3},{11,3} }, head = 1 },
  },
}
