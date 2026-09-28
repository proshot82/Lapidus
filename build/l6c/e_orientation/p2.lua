-- p2: проба «пара нужной стороной»: колонка слева, стояк справа, между ними 6 клеток
return {
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 9, 4 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 5, 3 }, { 6, 3 }, { 7, 3 } }, head = 3 },
  },
}
