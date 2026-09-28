return {
  id = 7, flat = 7, name = "Дали напор", length = { 2, 4 }, pressure = 3,
  grid = {
    "##########",
    "#####.####",
    "#####..###",
    "#####.####",
    "#......###",
    "#........#",
    "#...#....#",
    "#####.####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 6 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 } }, head = 2 },
  },
}
