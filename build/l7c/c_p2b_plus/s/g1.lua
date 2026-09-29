-- g1: эскиз «паром в щель» (без разметки). Слева туннель с тройником (вход в лифт снизу), над ним полка; справа очередь
-- «заглушка, щель, ниппель» под крышей, над щелью — жёлоб. Лапидус стартует на левой полке.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 4 }, pressure = 2,
  grid = {
    "############",
    "############",
    "#####.######",
    "#####..#####",
    "##........##",
    "##.##.#.#.##",
    "##........##",
    "#####.######",
    "############",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 7 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 5, 5 } }, head = 3 },
  },
}
