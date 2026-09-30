-- g1: находка gen3 (s4 i265), для разбора
local C = dofile("build/l8a/mk8.lua")
local d = C.build{ R = 3, L = { 2, 5 }, rows = {
  "#############",
  "#....p....X.#",
  "#...Q#.....K#",
  "#...........#",
  "#fH#......###",
  "###.........#",
  "####........#",
  "###.........#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { left = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { left = "V" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { right = "N" } },
} }
return d
