-- s9: s8 + переходник a (низ В, верх В) на полке над ванной; ванна K с входом Н — ногами её не взять без a.
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.n..a..#",
  "#####.#..#..#",
  "####Q.....X.#",
  "#####.......#",
  "#####.......#",
  "#####.......#",
  "#####fH.K...#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "N" } },
  n = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  a = { kind = "fitting", what = "coupling", tag = "cpl", ports = { down = "V", up = "V" } },
} }
