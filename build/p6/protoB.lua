-- Прототип Б из внешнего ревью 03.10 («Развилка над сливом»): проверка на движке игры. Решение не записано.
return {
  id = 92, flat = 92, name = "Развилка над сливом",
  length = { 3, 6 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#.........#",
    "#.........#",
    "#######~~##",
  },
  objects = {
    { kind = "source", at = { 10, 5 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 3 }, ports = { right = "V" } },
    { kind = "fixture", what = "heater", at = { 8, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 4 }, ports = { left = "N", right = "N", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl2", at = { 7, 3 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 8, 5 }, { 9, 5 } }, head = 1 },
  },
}
