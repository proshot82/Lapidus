-- Витрина арта (лист элементов): все латунные детали уровней. Не уровень.
return {
  id = 92, flat = 92, name = "Витрина: латунь",
  length = { 2, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#.........#",
    "###########",
    "#.........#",
    "###########",
    "#.........#",
    "###########",
  },
  objects = {
    { kind = "fitting", at = { 2, 2 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", at = { 4, 2 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", at = { 6, 2 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", at = { 8, 2 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", at = { 10, 2 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", at = { 2, 4 }, ports = { up = "N", left = "V" } },
    { kind = "fitting", at = { 4, 4 }, ports = { down = "N", left = "V" } },
    { kind = "fitting", at = { 6, 4 }, ports = { right = "N", down = "N" } },
    { kind = "fitting", at = { 8, 4 }, ports = { up = "V", right = "V", left = "V" } },
    { kind = "fitting", at = { 10, 4 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "fitting", at = { 4, 6 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 9, 6 }, { 10, 6 } }, head = 3 },
  },
}
