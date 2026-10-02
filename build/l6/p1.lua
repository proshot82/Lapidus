local M = dofile("build/l6/mk.lua")
return M.def{
  rows = {
    "#########",
    "#####F###",
    "#####.###",
    "#.......#",
    "#.......#",
    "#.......#",
    "#..S....#",
    "#####~###",
  },
  obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { right = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
  },
  lap = { { 8, 7 }, { 7, 7 }, { 7, 6 } },
  length = { 3, 5 },
  ablations = { { name = "без ниппеля", remove = "nip" }, { name = "кран запрещён", filter = M.noLift } },
}
