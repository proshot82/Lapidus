return {
  id = 10, flat = 10, name = "build/p6/fin/srch/c5_180.lua", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#############",
    "#############",
    "#############",
    "#######.....#",
    "#######.....#",
    "#...........#",
    "#######~~####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 11, 4 }, ports = { right = "V", left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 4 }, ports = { right = "N", left = "N" } },
    { kind = "lapidus", cells = { { 8, 5 }, { 9, 5 }, { 10, 5 } }, head = 1 },
  },
}
