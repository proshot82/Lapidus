-- s11: площадка для наблюдения: Q (В, слева), X (Н, справа), ванна K (В сверху), пробка p на высокой полке,
-- средний уступ и сухой крюк T.
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#####.p.....#",
  "#####.#.....#",
  "####Q.....X.#",
  "#####...#...#",
  "#####.......#",
  "#####.......#",
  "#####fH.K...#",
  "#############",
}, legend = {
  Q = { kind = "source", ports = { right = "V" } },
  X = { kind = "source", ports = { left = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
} }
