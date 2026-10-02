-- d1: семейство D «табуретка → звено, угольник-ниппель в шахте». Полка-коридор под потолком; слева к ней лезут только
-- с табуретки (муфта), справа — свободно, но оттуда ниппель толкается не в ту сторону. Ниппель с выходом вниз падает
-- в шахту и ловится мойкой на лету; голова входит снизу. Ложные планы: муфту сразу в стояк; лезть справа.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "d1", length = { 2, 4 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "###......#",
    "###.#.##.#",
    "###.#..#.#",
    "###...#..#",
    "#.......##",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 6 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 2 }, ports = { right = "N", down = "N" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 7, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
