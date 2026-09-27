local M = dofile("build/l6/mk.lua")
return M.def{
  rows = {
    "#########",
    "######F##",
    "######.##",
    "######.##",
    "#.......#",
    "#..n...S#",
    "#.......#",
    "#########",
  },
  obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { left = "V" } },
    n = { kind = "fitting", what = "nipple", tag = "nip", ports = { up = "N", down = "N" } },
  },
  lap = { { 2, 7 }, { 3, 7 }, { 4, 7 }, { 5, 7 } },
  length = { 3, 5 },
  ablations = { { name = "без ниппеля", remove = "nip" }, { name = "кран запрещён", filter = M.noLift } },
}
