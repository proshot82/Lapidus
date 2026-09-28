-- a15 (напор 3): стояк утоплен в пол, первая клетка фонтана — на уровне пола. Ванна на тумбе у верхней клетки
-- фонтана (вход вправо, Н) ловит на лету то, что фонтан поднимает. Нужный переходник (В|Н) делает вход ванны
-- «под голову»; муфта (В|В) — «под ноги», а ноги нужны угольнику. Угольник глушит фонтан сбоку — последним.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#..#....#",
    "#.......#",
    "####.####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 4, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 6 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 6 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 6 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 7, 6 } }, head = 2 },
  },
}
