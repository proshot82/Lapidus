-- кв. 9, кандидат b1: колонка под потолком (вход вниз, Н), стояк в полу под шахтой (выход вверх, Н).
-- Ложный план: тройник в шахту — на стояк. Замысел: тройник — в колонку, Лапидус головой в стояк.
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "b1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "#########.#",
    "#.........#",
    "#.......#.#",
    "#.........#",
    "#......##.#",
    "#.........#",
    "#######~~.#",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 10, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 10, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 8, 5 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 2, 7 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 4, 7 }, { 5, 7 } }, head = 2 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
