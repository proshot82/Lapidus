-- g7t: g7b при напоре 2 (вершина ниже)
local MK = dofile("build/l7c/d_tee_lift/mk.lua")
return MK.build{
  R = 2,
  rows = {
    "############",
    "############",
    "####.......#",
    "###........#",
    "##.e.......#",
    "#fHq.......#",
    "#S==T......#",
    "######F....#",
    "#######~~~~#",
  },
  legend = {
    S = { kind = "source", ports = { right = "V" } },
    ["="] = { kind = "pipe", what = "pipe", ports = { left = "N", right = "V" } },
    T = { kind = "pipe", what = "tee", ports = { left = "N", up = "V", right = "V" } },
    F = { kind = "fixture", what = "bath", ports = { up = "V" } },
    q = { kind = "fitting", what = "plug", ports = { left = "N" } },
    e = { kind = "fitting", what = "elbow", ports = { down = "N", right = "N" } },
  },
}
