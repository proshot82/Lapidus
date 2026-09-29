-- c2a: пробка и угольник стопкой в кармане слева; оба едут фонтаном направо; пробка — в боковой выход тройника,
-- угольник — сбоку в фонтан (толчок головой = подключение); пятки — в ванну.
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
return MK.build{
  rows = {
    "############",
    "#..........#",
    "#..........#",
    "#.......F..#",
    "#..........#",
    "#..e.......#",
    "#fHp.......#",
    "#S==T.....##",
    "######~~####",
  },
  legend = {
    S = { kind = "source", ports = { right = "V" } },
    ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
    T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
    F = { kind = "fixture", what = "bath", ports = { down = "V" } },
    p = { kind = "fitting", what = "plug", ports = { left = "N" } },
    e = { kind = "fitting", what = "elbow", ports = { down = "N", right = "N" } },
  },
}
