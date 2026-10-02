-- кв. 9, кандидат a1: тройник падает в шахту на стояк, заглушка — сбоку, ноги сверху, голова к мойке.
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "a1",
  length = { 3, 6 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "############",
    "#..........#",
    "#..........#",
    "#..........#",
    "#..........#",
    "#.####.#####",
    "#.####.#####",
    "#......#####",
    "######.#####",
    "############",
  },
  objects = {
    { kind = "source", at = { 7, 9 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 10, 5 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 4, 5 }, ports = { down = "V", up = "V", right = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 3, 5 } }, head = 1 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
