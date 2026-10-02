-- d2: семейство D, вторая раскладка (H=8, L=5): лаз к полке слева — только с табуретки-муфты; справа лезут свободно,
-- но оттуда ниппель толкается в лаз, а не в шахту. Мойка принимает только снизу, через ниппель-угольник (выход вниз).
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "d2", length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "####.....#",
    "####.#.#.#",
    "####.#.#.#",
    "####.#...#",
    "###......#",
    "#.......##",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 2 }, ports = { right = "N", down = "N" } },
    { kind = "lapidus", cells = { { 7, 7 }, { 8, 7 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
