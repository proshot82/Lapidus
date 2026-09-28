-- p1: проба механики «пара через слив»
return {
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#######~##",
  },
  objects = {
    { kind = "source", at = { 9, 5 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 5 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 2, 4 }, { 2, 3 } }, head = 3 },
  },
}
