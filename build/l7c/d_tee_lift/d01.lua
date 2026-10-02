-- d01: тройник (закреплён) на стояке «вверх ногами»: фонтан вверх + струя вбок по жёлобу.
-- Угольник (вниз Н, вправо Н) глушит фонтан сбоку; заглушка (влево Н) — боковой выход тройника.
-- Слева стопка: заглушка на стояке, угольник на заглушке.
local def = {
  id = 7, flat = 7, name = "Дали напор", length = { 2, 5 }, pressure = 3,
  grid = {
    "############",
    "#..........#",
    "#..........#",
    "#..........#",
    "#...#......#",
    "#..........#",
    "#..........#",
    "####.......#",
    "############",
  },
  objects = {
    { kind = "source", at = { 5, 8 }, ports = { right = "V" } },
    { kind = "pipe", what = "tee", tag = "tee", at = { 6, 8 }, ports = { left = "N", up = "V", right = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 6 }, ports = { down = "N", right = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 5 }, ports = { down = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 } }, head = 2 },
  },
}
local GV = dofile("build/l7c/d_tee_lift/gvis.lua")
def.visibleLoss = GV.make(def)
return def
