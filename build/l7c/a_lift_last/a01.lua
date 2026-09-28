-- a01: «пробка едет на лифте» — первый набросок. Замысел: перевёрнутый тройник на стояке бьёт вверх (лифт)
-- и влево (над сливом). Пробка должна заткнуть левый выход, угольник — фонтан сбоку, последним.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#~~~~####",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 6, 7 }, ports = { down = "V", up = "N", left = "N" } },
    { kind = "fixture", what = "bath", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 8, 5 }, ports = { right = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 7, 5 }, ports = { down = "V", left = "V" } },
    { kind = "lapidus", cells = { { 8, 8 }, { 7, 8 } }, head = 2 },
  },
}
