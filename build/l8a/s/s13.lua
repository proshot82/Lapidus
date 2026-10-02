-- s13: s8 + переходник a (низ В, верх В) на выступе, ванна с входом Н (ногами только через a).
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.p.....#",
  "#####.#.....#",
  "####Q..a..X.#",
  "########....#",
  "#######.....#",
  "#######.....#",
  "#######.K.fH#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "N" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
  a = { kind = "fitting", what = "coupling", tag = "cpl", ports = { down = "V", up = "V" } },
} }
