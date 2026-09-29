-- прототип p5: 9×10; стояк в стене над крючьями, унитаз в трёх клетках; комната-кольцо справа от унитаза,
-- ноги на старте свешены в жёлоб; жёлоб на полку у шахты (необратимо); 4 крюка над сливом
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
    "##......#",
    "##...####",
    "##~~~####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 6, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 8, 5 }, { 8, 4 }, { 8, 3 }, { 7, 3 } }, head = 4 },
  },
}
