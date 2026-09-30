-- s10: «два крана» + переходник a на ванну (стрелять им только с Q, пока не перехватился на X; с X он уходит в Q).
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.p.....#",
  "#####.#a....#",
  "#####..#....#",
  "####Q.....X.#",
  "#####.......#",
  "#####.......#",
  "#####fH.K...#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "N" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  a = { kind = "fitting", what = "coupling", tag = "cpl", ports = { down = "V", up = "V" } },
} }
