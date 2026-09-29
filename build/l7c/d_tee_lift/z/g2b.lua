-- g2b (вариант семейства g1/g2)
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
return MK.build{
  rows = {
    "#########",
    "####.####",
    "##.....##",
    "#.......#",
    "#f......#",
    "#o......#",
    "#Heq...F#",
    "#S==T..##",
    "#####~~##",
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
