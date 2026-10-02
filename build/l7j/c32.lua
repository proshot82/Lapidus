-- l7j c32: кандидат кв. 7 (собран build/l7j/mk7.py). Решение не пишется.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "c32",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "##########",
    "##......##",
    "##.###..##",
    "##......##",
    "##......##",
    "##......##",
    "#.......##",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 8, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 6, 8 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 3 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 5, 3 }, { 6, 3 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
