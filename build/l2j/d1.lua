-- l2j/d1: «Полка» с шахтой. Ниппель лежит на спине Лапидуса над двумя столбами: левый (x=3) ведёт к стояку, правый (x=4) —
-- на резьбу унитаза (ловушка). Колодец внизу закрыт сверху; в него попадают только шахтой x=3, встав на окаменевший ниппель.
return {
  id = 2, flat = 2, name = "Полка",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "########",
    "##..####",
    "##....##",
    "##....##",
    "##..####",
    "##..####",
    "#....###",
    "##....##",
    "###~~###",
  },
  objects = {
    { kind = "source", at = { 2, 7 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 3, 8 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 4, 4 }, { 5, 4 }, { 5, 3 } }, head = 3 },
  },
  ablations = { { name = "без ниппеля", remove = "nip" } },
  texts = { request = "", hints = { "", "", "" } },
}
