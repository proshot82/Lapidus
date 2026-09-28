-- a16 (напор 3): антресоль над ванной с двумя переходниками; достать их можно только с верхушки фонтана.
-- Нужный (В|Н) делает вход ванны «под голову», муфта (В|В) — «под ноги» (а ноги нужны угольнику).
-- Угольник у фонтана — полочка, на которую падает переходник; им же глушат фонтан сбоку последним.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "###.....#",
    "####....#",
    "####....#",
    "####.####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 4, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 3, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 6 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 7, 6 } }, head = 2 },
  },
}
