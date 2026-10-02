-- l7j c2: кандидат кв. 7 (собран build/l7j/mk7.py). Решение не пишется.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "c2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "#........#",
    "#..#.....#",
    "#........#",
    "#...#.#..#",
    "#........#",
    "#........#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 7, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 4, 2 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 4 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 7, 8 }, { 8, 8 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
