-- прототип: шахта вдвое выше (4 крюка), колодец со сливом
return {
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 30, fb = 2 },
  grid = {
    "#########",
    "##......#",
    "#...#####",
    "#...#####",
    "#...#####",
    "#...##..#",
    "##......#",
    "##...####",
    "##~~~####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 3, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 6, 7 }, { 7, 7 }, { 8, 7 } }, head = 3 },
  },
}
