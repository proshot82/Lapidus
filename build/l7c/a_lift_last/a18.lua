-- a18 (напор 3): антресоль слева от верхушки фонтана: муфта, переходник, угольник в ряд. Толкать ряд вправо:
-- угольник уходит на фонтан и дальше падает в прорезь у основания, переходник остаётся плясать на фонтане.
-- Лишний толчок ставит на фонтан муфту. Финал: угольник сбоку глушит фонтан, переходник падает в ванну.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "##########",
    "#........#",
    "#........#",
    "####.....#",
    "#####....#",
    "#####....#",
    "#####.####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 9, 6 }, { 8, 6 } }, head = 2 },
  },
}
