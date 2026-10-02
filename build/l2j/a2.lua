-- l2j/a2: «Над сливом», первый скелет. Муфта на стояке, Лапидус — труба над сливом; крючья C (слева), B (подвес), A (над унитазом).
return {
  id = 2, flat = 2, name = "Над сливом",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "##########",
    "#......###",
    "#......###",
    "#........#",
    "#........#",
    "#........#",
    "#....#...#",
    "##.......#",
    "####~~~~##",
  },
  objects = {
    { kind = "source", at = { 3, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fixture", what = "toilet", at = { 9, 8 }, ports = { left = "N" } },
    { kind = "stub", tag = "A", at = { 9, 7 }, ports = { left = "V" } },
    { kind = "stub", tag = "B", at = { 7, 3 }, ports = { left = "N" } },
    { kind = "stub", tag = "C", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 2, 6 } }, head = 2 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без A", remove = "A" },
    { name = "без B", remove = "B" },
    { name = "без C", remove = "C" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
