-- s7: «два крана», скелет: Q в стене слева (В), X справа (Н), пробка на полке (7,3), ванна K (В) ногами.
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.......#",
  "#####.n.....#",
  "#####.#.....#",
  "####Q.....X.#",
  "#####.......#",
  "#####.......#",
  "#####fH#K...#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
  n = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
} }
