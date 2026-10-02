-- Кв. 10 «Опрессовка», кандидат o2 (зонд, компактнее o1): полка короче, нижняя комната 9 клеток. Решение здесь не пишется.
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 6 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  grid = {
    "############",
    "#......#####",
    "#..........#",
    "####.#######",
    "#.........##",
    "#.........##",
    "####.#######",
    "############",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 10, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 3 }, ports = { down = "V", left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 9, 3 }, { 10, 3 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
