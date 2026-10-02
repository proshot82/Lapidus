-- s6: «два крана»: Q (В, слева, стартовый якорь), X (Н, справа, к нему не подойти без якоря), пробка n на полке —
-- в Q струёй с X; ванна K (В) — ногами. Скелет без ловушек (проверка геометрии).
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#...........#",
  "#......n....#",
  "#......#....#",
  "#...Q.....X.#",
  "#...#.......#",
  "#...#.......#",
  "#fH.#..##K..#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
  n = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
} }
