-- g1a: заглушка бокового выхода (q) и угольник (e) стопкой в кармане слева; фонтан везёт обоих направо
-- (кто поехал первым — выйдет последним): q падает в боковой выход тройника, e — на q; Лапидус с ванны
-- (справа) вталкивает e в фонтан сбоку головой — толчок и есть подключение.
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
return MK.build{
  rows = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#..e.....#",
    "#fHq....F#",
    "#S==T..###",
    "#####~~###",
  },
  legend = {
    S = { kind = "source", ports = { right = "V" } },
    ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
    T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
    F = { kind = "fixture", what = "bath", ports = { left = "V" } },
    q = { kind = "fitting", what = "plug", ports = { left = "N" } },
    e = { kind = "fitting", what = "elbow", ports = { down = "N", right = "N" } },
  },
}
