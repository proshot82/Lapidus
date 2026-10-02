-- кв. 9, кандидат e4. 
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "e4",
  length = { 3, 6 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "#########",
    "######.##",
    "#......##",
    "#..###.##",
    "#......##",
    "##.#.#.##",
    "#......##",
    "####~~.##",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 6, 5 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 5 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 3, 4 }, { 2, 4 } }, head = 1 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
