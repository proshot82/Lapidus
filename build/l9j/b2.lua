-- кв. 9, кандидат b2: колонка в потолке над стояком (вход вниз, Н), стояк в полу (выход вверх, Н);
-- слева от верха стояка — низкий лаз над сливом (туда заглушку не донести, Лапидус проползает).
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "b2",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "#######.##",
    "#........#",
    "#........#",
    "#....##..#",
    "#.......##",
    "#....~~.##",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 8, 7 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 9, 5 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 2, 6 }, { 2, 5 }, { 2, 4 } }, head = 3 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
