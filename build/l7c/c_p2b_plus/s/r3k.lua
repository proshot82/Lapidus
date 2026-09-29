-- r3k: эскиз (r3j, длина 2–6)
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 6 }, pressure = 3,
  grid = {
    "###########",
    "#####.#####",
    "#####..####",
    "###......##",
    "###.#.#...#",
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
        { kind = "lapidus", cells = { { 8, 4 }, { 9, 4 }, { 9, 5 }, { 10, 5 }, { 10, 6 } }, head = 5 },
  },
}
