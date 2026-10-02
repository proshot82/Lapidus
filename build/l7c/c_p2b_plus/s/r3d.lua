-- r3d: эскиз k7 при напоре 3 (без разметки): столб выше на клетку, слева комнатка 2×3, справа комната 3×2 и очередь.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "###########",
    "#####.#####",
    "#####..####",
    "###......##",
    "###...#...#",
    "###...#...#",
    "#####.....#",
    "#####.#####",
    "###########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 6 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 8, 5 }, { 9, 5 }, { 10, 5 }, { 10, 6 }, { 10, 7 } }, head = 5 },
  },
}
