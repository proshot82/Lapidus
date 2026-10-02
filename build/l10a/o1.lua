-- Кв. 10 «Опрессовка», кандидат o1 (зонд устройства): тройник на стояк через шахту, муфта и ниппель — пара,
-- которая по резьбе подходит в обе ветки (к мойке и к унитазу); Лапидус — звено другой ветки. Напор 1.
-- Решение здесь не пишется.
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 6 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  grid = {
    "##############",
    "#............#",
    "#............#",
    "#####.########",
    "##.........###",
    "##.........###",
    "#####.########",
    "##############",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 11, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 9, 3 }, ports = { down = "V", left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 12, 3 }, { 13, 3 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = {
    request = "Опрессовка.",
    card = nil,
    hints = { "—", "—", "—" },
  },
}
