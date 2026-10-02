-- s19 (s8 при R=3, L=2..3): «два крана» (Q слева В, X справа Н на ряду 4), пробка на полке у потолка, ванна K (В).
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 3, L = { 2, 3 }, rows = {
  "#############",
  "#####.n.....#",
  "#####.#.....#",
  "####Q.....X.#",
  "#####.......#",
  "#####.......#",
  "#####.......#",
  "#####fH.K...#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
  n = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
} }
