-- Кв. 10 «Опрессовка», зонд o4 (o3 с верными зазорами: слева 2 клетки под пару, справа 4 под Лапидуса).
-- Решение здесь не пишется.
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 5 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  grid = {
    "##############",
    "###..........#",
    "###..........#",
    "###..........#",
    "######.#######",
    "##############",
  },
  objects = {
    { kind = "source", at = { 7, 5 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 4, 4 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 12, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 8, 4 }, ports = { down = "V", left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 9, 4 }, { 9, 3 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
