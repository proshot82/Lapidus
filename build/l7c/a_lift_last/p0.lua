-- проба физики: тройник на стояке, фонтан, Лапидус катается
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 5, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 7 }, ports = { down = "V", up = "N", right = "V" } },
    { kind = "fixture", what = "bath", at = { 8, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 5 }, ports = { down = "V" } },
    { kind = "lapidus", cells = { { 2, 8 }, { 3, 8 }, { 4, 8 } }, head = 3 },
  },
}
