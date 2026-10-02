-- a1c (вариант a1): эскиз (без разметки). Переходник — проставка под тройником (напор 3, длина 2–3).
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 3 }, pressure = 3,
  grid = {
    "############",
    "#####.######",
    "#####..#####",
    "#####.######",
    "#####.######",
    "##.........#",
    "##.........#",
    "#####......#",
    "#####.######",
    "############",
  },
  objects = {
    { kind = "source", at = { 6, 9 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 7 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 8 }, ports = { down = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 8, 8 }, ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 8 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 11, 7 }, { 11, 8 }, { 10, 8 } }, head = 3 },
  },
}
