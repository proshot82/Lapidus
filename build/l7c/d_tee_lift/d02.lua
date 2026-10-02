-- d02: компактный вариант d01 (поле 12×8). Тройник закреплён на стояке «вверх ногами».
local def = {
  id = 7, flat = 7, name = "Дали напор", length = { 2, 5 }, pressure = 3,
  grid = {
    "############",
    "#..........#",
    "#..........#",
    "#..#.......#",
    "#..........#",
    "#..........#",
    "###........#",
    "############",
  },
  objects = {
    { kind = "source", at = { 4, 7 }, ports = { right = "V" } },
    { kind = "pipe", what = "tee", tag = "tee", at = { 5, 7 }, ports = { left = "N", up = "V", right = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 5 }, ports = { down = "N", right = "N" } },
    { kind = "fixture", what = "bath", at = { 7, 4 }, ports = { down = "V" } },
    { kind = "lapidus", cells = { { 2, 6 }, { 3, 6 } }, head = 2 },
  },
}
local GV = dofile("build/l7c/d_tee_lift/gvis.lua")
def.visibleLoss = GV.make(def)
return def
