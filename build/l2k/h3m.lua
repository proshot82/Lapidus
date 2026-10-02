-- hc2.lua из build/l2k/h3.lua, балл -0.8: ход 23 скр 0% обез 1.27% шир 1 глуб 0 сост 635
local d = dofile("build/l2k/h3.lua")
d.grid = {
  "########",
  "#....#.#",
  "#..#..##",
  "#.#....#",
  "#...#..#",
  "#......#",
  "#....#.#",
  "#~~~~~~#",
}
d.objects = {
  {kind="stub", ports={right="N"}, at={2,5}, tag="hook"},
  {kind="fixture", ports={right="N"}, at={2,7}, what="toilet"},
  {kind="source", ports={left="N"}, at={7,6}},
  {at={5,2}, kind="fitting", ports={right="V",left="V"}, tag="cpl", what="coupling"},
  {kind="lapidus", head=3, cells={{2,2},{2,3},{2,4}}},
}
return d
