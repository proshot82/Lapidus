-- s4: «две точки сети»: A (В, на уступе слева) — стрелять; B (Н, у пола) — финальный якорь; адаптер n с полки — на ванну;
-- пробка p — закрыть A после переподключения.
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#...........#",
  "#........n..#",
  "#........#..#",
  "#A.p........#",
  "####........#",
  "####........#",
  "####.fH.B..K#",
  "#############",
}, legend = {
  A = { kind = "source", ports = { right = "V" } },
  B = { kind = "source", ports = { up = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
  n = { kind = "fitting", what = "elbow", tag = "elb", ports = { down = "N", left = "V" } },
  p = { kind = "fitting", what = "plug", tag = "plug", ports = { left = "N" } },
} }
