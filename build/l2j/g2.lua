-- l2j/g2: «Сначала муфта». Ниппель на столбике достаёт только голова Лапидуса, висящего ногами на потолочном крюке (с пола
-- к нему не подступиться: выступ стены). Ванна на кронштейне. Старт на крюке: первый естественный ход — столкнуть ниппель —
-- и есть ловушка (он лёг слева от муфты). Верно: спуститься, увести муфту к стояку, снова повиснуть, столкнуть ниппель.
return {
  id = 2, flat = 2, name = "Сначала муфта",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "##########",
    "#.......##",
    "#.......##",
    "#.......##",
    "#....##.##",
    "#....#...#",
    "##......##",
    "##########",
  },
  objects = {
    { kind = "stub", tag = "H", at = { 8, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 3, 7 }, ports = { right = "N" } },
    { kind = "fixture", what = "bath", at = { 9, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 8, 3 }, { 8, 4 } }, head = 2 },
  },
  ablations = { { name = "без муфты", remove = "cpl" }, { name = "без ниппеля", remove = "nip" }, { name = "без крюка", remove = "H" } },
  texts = { request = "", hints = { "", "", "" } },
}
