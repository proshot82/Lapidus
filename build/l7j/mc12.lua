-- l7j c12: кандидат кв. 7 (собран build/l7j/mk7.py). Решение не пишется.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "c12",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#..#......#",
    "#......#..#",
    "#.........#",
    "#.........#",
    "#.........#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 5, 8 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 3 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 5, 7 }, { 5, 6 }, { 5, 5 }, { 5, 4 }, { 5, 3 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  wallCost = 0.4,
  fixedPieces = { "ada", "elb" },
  fixedLap = true,
  optRange = { 24, 32 },
  want = { ada = { 3, 8 }, elb = { 4, 8 } },
  protect = { {3,8},{4,8},{4,7},{4,6},{5,6},{6,6},{7,6},{3,7},{3,6},{3,5},{3,4},{3,3},{4,4},{8,5},{5,8},{5,7},{5,6},{5,5},{5,4},{5,3},{4,3} },
  texts = { request = "", hints = { "", "", "" } },
}
