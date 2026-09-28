return {
  id = 7, flat = 7, name = "Дали напор", length = { 2, 3 }, pressure = 3,
  grid = {
    "########",
    "#####.##",
    "#####.##",
    "#####.##",
    "#####.##",
    "#.....##",
    "#.....##",
    "#####.##",
    "########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 6, 2 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 7 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 2, 6 } }, head = 2 },
  },
}
