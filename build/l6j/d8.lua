-- d8: муфта лежит у самого стояка (4,7): естественный план — дотолкнуть её в стояк одним толчком; верный — обойти её сверху через нишу (3,6) и оттолкнуть ВПРАВО под лаз. (8,6) замурована.
-- d4: d2, растянутая вправо на столбец (W=11): муфта стартует дальше от табуретки, правый подъём — столбец 10.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "d8", length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "####......#",
    "####.#.##.#",
    "####.#.##.#",
    "####.#..#.#",
    "##.....#..#",
    "#........##",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 2 }, ports = { right = "N", down = "N" } },
    { kind = "lapidus", cells = { { 9, 7 }, { 9, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
