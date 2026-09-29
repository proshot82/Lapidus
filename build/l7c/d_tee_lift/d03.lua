-- d03: как d02, но справа полка с «тоннелем» (потолок над подходом к угольнику), ванна над полкой.
local def = {
  id = 7, flat = 7, name = "Дали напор", length = { 2, 5 }, pressure = 3,
  grid = {
    "############",
    "#..........#",
    "#..........#",
    "#..........#",
    "#..#.......#",
    "#.....#....#",
    "#..........#",
    "###...######",
    "############",
  },
  objects = {
    { kind = "source", at = { 4, 8 }, ports = { right = "V" } },
    { kind = "pipe", what = "tee", tag = "tee", at = { 5, 8 }, ports = { left = "N", up = "V", right = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 6 }, ports = { down = "N", right = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 5 }, ports = { down = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 } }, head = 2 },
  },
}
return def
