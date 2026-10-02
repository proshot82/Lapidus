-- l2j/f2: из случайного поиска mk5 (seed 1). Стояк Н и ванна В на одной полке (ряд 4) над полом с ямой слева;
-- муфта и ниппель на полке, Лапидус под полкой. Решение не записано.
return {
  id = 2, flat = 2, name = "Две детали",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "#....#...#",
    "#........#",
    "##~#######",
  },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "fixture", what = "bath", at = { 9, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 5, 5 } }, head = 2 },
  },
  ablations = { { name = "без муфты", remove = "cpl" }, { name = "без ниппеля", remove = "nip" } },
  texts = { request = "", hints = { "", "", "" } },
}
