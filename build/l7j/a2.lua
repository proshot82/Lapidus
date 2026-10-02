-- l7j a2: как a1, шире слева (переходник не запечатан), угольник у ямы.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "a2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "#############",
    "#...........#",
    "#...........#",
    "#...........#",
    "#####.#.#####",
    "#####.......#",
    "#####......##",
    "#####......##",
    "######~~~~~##",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 12, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 4, 4 }, ports = { down = "V", up = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 7, 4 }, ports = { down = "V", right = "N" } },
    { kind = "lapidus", cells = { { 10, 4 }, { 11, 4 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
