-- s17: s8 + ванна с входом Н и переходник a (низ В, верх В) на уступе у ванны.
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.n.....#",
  "#####.#.....#",
  "####Q.....X.#",
  "#####.......#",
  "#####.......#",
  "#####...a...#",
  "#####fH.#K..#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "N" } },
  n = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  a = { kind = "fitting", what = "coupling", tag = "cpl", ports = { down = "V", up = "V" } },
} }
