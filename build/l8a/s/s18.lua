-- s18: s8, пробка на выступе (8,4): с X ногами — влево в Q; с Q головой — вправо, на средний уступ.
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.......#",
  "#####.......#",
  "####Q..n..X.#",
  "#####.##....#",
  "#####....##.#",
  "#####.......#",
  "#####fH.K...#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
  n = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
} }
