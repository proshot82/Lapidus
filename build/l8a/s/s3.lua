-- s3: «пробка на полке, фонтан X в полу, стреляем с X, пробка → в X, финал через второй выход»
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
  "#############",
  "#...........#",
  "#........c..#",
  "#........#..#",
  "#...........#",
  "#...........#",
  "#...........#",
  "#fooH.KYA...#",
  "#############",
}, legend = {
  A = { kind = "source", ports = { up = "V", left = "V" } },
  Y = { kind = "pipe", what = "pipe", ports = { right = "N", up = "N" } },
  K = { kind = "fixture", what = "bath", ports = { up = "V" } },
} }
