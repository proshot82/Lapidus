-- e3: раунд e, ядро «Лапидус — звено стояка». мойка на уровне полки (8,2): ниппель ловится на самом верху шахты; L 4–5 — разворот в шахте невозможен.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "e3", length = { 4, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "####....#",
    "####.#.##",
    "####.#.##",
    "####.#.##",
    "##.....##",
    "#......##",
    "######.##",
    "#########",
  },
  objects = {
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 2 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 7 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 2 }, ports = { right = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 }, { 3, 6 }, { 4, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
