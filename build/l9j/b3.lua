-- кв. 9, кандидат b3: колонка в потолке над шахтой, стояк на дне шахты; полка к колонке слева; лаз над сливом у стояка.
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "b3",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "#######.###",
    "#.......###",
    "#....##..##",
    "#.......###",
    "#.....#.###",
    "#.......###",
    "#####~~.###",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 8, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 5 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 3, 7 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 4, 7 }, { 5, 7 }, { 6, 7 } }, head = 3 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
