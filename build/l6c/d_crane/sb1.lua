-- песочница: проверка механики перехвата (не кандидат)
return {
  id = 6, flat = 6, name = "t", length = { 3, 5 }, pressure = 0,
  grid = {
    "########",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "########",
  },
  objects = {
    { kind = "source", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "fixture", what = "heater", at = { 3, 1+1 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "n", at = { 3, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 4 }, { 4, 4 }, { 4, 5 }, { 4, 6 }, { 3, 6 } }, head = 5 },
  },
}
