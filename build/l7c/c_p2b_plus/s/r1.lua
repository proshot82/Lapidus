-- r1: эскиз (без разметки). Фонтан — лифт и для Лапидуса, пока пуст: тройник наверху слева, вниз — только сбросом.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "############",
    "############",
    "##....######",
    "###.#..#####",
    "###.#.######",
    "##.........#",
    "##.........#",
    "#####......#",
    "#####.######",
    "############",
  },
  objects = {
    { kind = "source", at = { 6, 9 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 3 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 8 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 8 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 11, 7 }, { 11, 8 }, { 10, 8 } }, head = 3 },
  },
}
