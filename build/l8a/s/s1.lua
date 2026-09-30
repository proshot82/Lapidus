-- s1: эскиз «два устья, пробка на полке между ними» (проба динамики)
local C = dofile("build/l8a/mk8.lua")
return C.build{ R = 2, L = { 2, 5 }, rows = {
"#############",
  "#...........#",
  "#......c....#",
  "#......#....#",
  "#...........#",
  "#...........#",
  "#..........K#",
  "#fooH.A=U...#",
  "#############",
}, legend = {
  A = { kind = "source", ports = { up = "V", right = "V" } },
  K = { kind = "fixture", what = "bath", ports = { left = "N" } },
} }
