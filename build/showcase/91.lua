-- Витрина арта (лист элементов): приборы, сеть, слив, фаянс, Лапидус. Не уровень.
return {
  id = 91, flat = 91, name = "Витрина: приборы и сеть",
  length = { 2, 6 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#.........#",
    "#.........#",
    "#.........#",
    "#.........#",
    "#####~~####",
  },
  objects = {
    { kind = "fixture", what = "bath", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 4, 3 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 6, 3 }, ports = { down = "V" } },
    { kind = "fixture", what = "washer", at = { 8, 3 }, ports = { up = "V" } },
    { kind = "fixture", what = "dryer", at = { 10, 3 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 2, 5 }, ports = { down = "N" } },
    { kind = "stub", at = { 10, 5 }, ports = { left = "N" } },
    { kind = "source", at = { 10, 7 }, ports = { up = "N" } },
    { kind = "porcelain", at = { 8, 7 } },
    { kind = "lapidus", cells = { { 6, 5 }, { 5, 5 }, { 4, 5 }, { 4, 6 }, { 4, 7 }, { 3, 7 } }, head = 1 },
  },
}
