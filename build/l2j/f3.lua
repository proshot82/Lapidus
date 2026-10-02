-- l2j/f3: «Не той стороной свинтил». Муфта В–В лежит на полу под полкой, ниппель Н–Н — на полке. Пара муфта+ниппель нужна
-- стояку (Н) муфтой вперёд; свинтятся они навсегда при первом касании. Сброшенный с полки влево ниппель ложится слева от
-- муфты — пара соберётся не той стороной (ни к стояку, ни к ванне не подойдёт), и это видно не сразу. Верно — сбросить вправо.
return {
  id = 2, flat = 2, name = "Не той стороной свинтил",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "##..##...#",
    "##.......#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "fixture", what = "bath", at = { 9, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 6 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 6, 4 }, { 6, 3 } }, head = 2 },
  },
  ablations = { { name = "без муфты", remove = "cpl" }, { name = "без ниппеля", remove = "nip" } },
  texts = { request = "", hints = { "", "", "" } },
}
