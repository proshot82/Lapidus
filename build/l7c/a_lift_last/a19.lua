-- a19 (напор 3): ужатая a18. Антресоль (ряд из муфты, переходника, угольника) слева от верхушки фонтана,
-- над ней лаз; справа — только карман для U-образного Лапидуса. Финал — угольник сбоку, переходник падает в ванну.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.....###",
    "#......##",
    "####....#",
    "#####...#",
    "#####...#",
    "#####.###",
    "#########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 8, 5 } }, head = 2 },
  },
}
