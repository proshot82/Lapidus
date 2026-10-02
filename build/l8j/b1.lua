-- b1: «лифт на якоре» — угольник падает в шахту и прикипает к стояку на лету; Лапидус висит на нём головой,
-- муфту ловит на себя, втягивается под неё ногами и поднимает к мойке. Черновик.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 8, flat = 8, name = "b1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "######.####",
    "######.####",
    "######....#",
    "######...##",
    "######.####",
    "#####..####",
    "######~####",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 6, 7 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 9, 5 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 10, 4 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 8, 5 }, { 8, 4 } }, head = 2 },
  },
  ablations = { { name = "без угольника", remove = "elb" }, { name = "без муфты", remove = "cpl" } },
}
