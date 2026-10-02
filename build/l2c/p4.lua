-- прототип p4: 10×10, финальная сборка длиной 3; комната-кольцо 2×2 справа от унитаза, ноги свешены в жёлоб
return {
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 30, fb = 2 },
  grid = {
    "##########",
    "##.......#",
    "#...###..#",
    "#...####.#",
    "#...####.#",
    "#...####.#",
    "##.......#",
    "##...#####",
    "##~~~#####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 3, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 7, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 9, 5 }, { 9, 4 }, { 9, 3 }, { 8, 3 } }, head = 4 },
  },
}
