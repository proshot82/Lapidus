-- l7j m1_6: мутатор build/l7j/mut.lua от build/l7j/mbase1.lua (seed 6). Решение не пишется.
-- метрики: ходов 22, ширина 6, прогулка 13, скрытых 76%, обезьяна 0.00, глубина 15, двери 1/1, событий 2, сост 34372, конфиг 1, счёт -43.2
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "m1_6",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "########",
    "#......#",
    "#.#..#.#",
    "#......#",
    "#.#....#",
    "#......#",
    "#......#",
    "#..##.##",
    "########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 6, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 3, 2 }, ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 3, 4 }, ports = { right = "N", down = "V" } },
    { kind = "lapidus", cells = { { 6, 7 }, { 7, 7 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
