-- l2j/b1: «Под лестницей». Муфта на уступе между двумя шахтами: левая ведёт к стояку (верно), правая — к крюку над унитазом
-- (муфта окаменеет на крюке — ловушка). Лапидус: по левой шахте на муфту, тоннелем под уступом, головой на крюк, ногами в муфту,
-- потом голову в унитаз. Лапидус — труба над сливом.
return {
  id = 2, flat = 2, name = "Под лестницей",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "#########",
    "##.....##",
    "##.....##",
    "##.....##",
    "##.##.###",
    "##.##.###",
    "##.....##",
    "#......##",
    "###~~~###",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fixture", what = "toilet", at = { 7, 8 }, ports = { left = "N" } },
    { kind = "stub", tag = "A", at = { 7, 7 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 4, 4 }, { 4, 3 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без крюка", remove = "A" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
