-- прототип p9: 9×10; жёлоб → уступ → падение на полку у шахты; 5 крючьев; слив в нижнем ряду
return {
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 30, fb = 2 },
  grid = {
    "#########",
    "#.......#",
    "#...##..#",
    "#...###.#",
    "#...###.#",
    "#...###.#",
    "#...#...#",
    "##....###",
    "##...####",
    "##~~~####",
  },
  objects = {
    { kind = "source", at = { 2, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 6, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 8, 5 }, { 8, 4 }, { 8, 3 }, { 7, 3 } }, head = 4 },
  },
}
