-- e2: раунд e, ядро «Лапидус — звено стояка». Ниша в шахту на уровне (6,6); правого подъёма нет — после ранней муфты лестницей в шахте служит сама муфта. L 3–5, старт на полу.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "e2", length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##.....##",
    "##.....##",
    "####.#..#",
    "##.....##",
    "##.....##",
    "##.....##",
    "#......##",
    "##.....##",
    "##.....##",
  },
  objects = {
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 7 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 2 }, ports = { right = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 }, { 3, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
