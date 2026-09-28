-- песочница: подъём пары (деталь на полу свинчена с деталью на голове) — не кандидат
return {
  id = 6, flat = 6, name = "t", length = { 3, 5 }, pressure = 0,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "###.#####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 2 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 3, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 5 }, ports = { left = "N", down = "N" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 5, 5 }, { 4, 6 } }, head = 3 },
  },
}
