-- l2j/b2: вариант b1 с тоннелем в один ряд и правой шахтой в две клетки (из перебора mk1: tun1 shaft2 A(7,6,left) cpl5 lapL).
return {
  id = 2, flat = 2, name = "Под лестницей",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "##########",
    "##......##",
    "##......##",
    "##......##",
    "##.##...##",
    "##.##...##",
    "##.##...##",
    "#.......##",
    "###~~~~###",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fixture", what = "toilet", at = { 8, 8 }, ports = { left = "N" } },
    { kind = "stub", tag = "A", at = { 8, 6 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 4, 4 }, { 4, 3 } }, head = 2 },
  },
  ablations = { { name = "без муфты", remove = "cpl" }, { name = "без крюка", remove = "A" } },
  texts = { request = "", hints = { "", "", "" } },
}
