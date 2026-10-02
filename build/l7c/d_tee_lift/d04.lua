-- d04: «сначала лифт до стены, потом глушить». Тройник (закреплён, вверх ногами) питается от стояка в стене
-- через трубу; второй выход стояка бьёт в шахту за стеной. Заглушка шахты лежит на верху стены — достать её можно
-- только с верхушки фонтана. Заглушка фонтана лежит рядом, на трубе.
local GV = dofile("build/l7c/d_tee_lift/gvis2.lua")
local def = {
  id = 7, flat = 7, name = "Дали напор", length = { 2, 5 }, pressure = 3,
  grid = {
    "##########",
    "#........#",
    "#......#.#",
    "#......#.#",
    "#......#.#",
    "#......#.#",
    "#......#.#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 8, 8 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "pipe", at = { 7, 8 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "pipe", at = { 6, 8 }, ports = { left = "N", right = "V" } },
    { kind = "pipe", what = "tee", tag = "tee", at = { 5, 8 }, ports = { left = "N", up = "V", right = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 6, 7 }, ports = { down = "N" } },
    { kind = "fitting", what = "plug", tag = "p2", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "fixture", what = "bath", at = { 2, 6 }, ports = { down = "V" } },
    { kind = "lapidus", cells = { { 7, 7 }, { 7, 6 } }, head = 2 },
  },
}
def.visModes = GV.modes(def)
def.visibleLoss = def.visModes.wide
return def
