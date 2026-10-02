-- l7j a1: переходник под угольник (якорь на клетку выше). Черновик.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "a1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "############",
    "#.........##",
    "#.........##",
    "#.........##",
    "###.#.######",
    "###.......##",
    "###......###",
    "###......###",
    "####~~~~~###",
  },
  objects = {
    { kind = "source", at = { 4, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 10, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 3, 3 }, ports = { down = "V", up = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 4 }, ports = { down = "V", right = "N" } },
    { kind = "lapidus", cells = { { 9, 4 }, { 10, 4 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
