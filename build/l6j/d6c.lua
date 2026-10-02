-- d6c: d6, Лапидус стартует на полке справа от ниппеля (первый соблазн — толкнуть ниппель влево).
-- d4: d2, растянутая вправо на столбец (W=11): муфта стартует дальше от табуретки, правый подъём — столбец 10.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "d6c", length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "####......#",
    "####.#.##.#",
    "####.#.##.#",
    "####.#..#.#",
    "####...#..#",
    "#........##",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 8, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 2 }, ports = { right = "N", down = "N" } },
    { kind = "lapidus", cells = { { 8, 2 }, { 9, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
