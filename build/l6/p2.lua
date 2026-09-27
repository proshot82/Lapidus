local M = dofile("build/l6/mk.lua")
return M.def{
  rows = {
    "#######",
    "###F###",
    "###.###",
    "#.....#",
    "#.....#",
    "#S....#",
    "###~###",
  },
  obj = {
    F = { kind = "fixture", what = "heater", ports = { down = "V" } },
    S = { kind = "source", ports = { right = "V" } },
  },
  lap = { { 5, 6 }, { 6, 6 }, { 6, 5 } },
  length = { 3, 5 },
  ablations = { { name = "без ниппеля", remove = "nip" }, { name = "кран запрещён", filter = M.noLift } },
}
