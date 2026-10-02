-- r3: эскиз (без разметки). Как r2, но Лапидус стартует слева, рядом с заглушкой.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "############",
    "############",
    "###...######",
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
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 8 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 6 }, { 3, 7 }, { 4, 7 } }, head = 3 },
  },
}
