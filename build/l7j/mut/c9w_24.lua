-- l7j c9w_24: мутатор build/l7j/mut.lua от build/l7j/mc9w.lua (seed 24). Решение не пишется.
-- метрики: ходов 31, ширина 5, прогулка 10, скрытых 34%, обезьяна 0.00, глубина 21, двери 0/1, событий 9, сост 74838, конфиг 1, счёт 9.1
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "c9w_24",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "############",
    "#.#..#.....#",
    "##......#..#",
    "#..........#",
    "#.....#...##",
    "##......#..#",
    "#..........#",
    "#..........#",
    "############",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 10, 8 }, ports = { right = "N", left = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 9, 2 }, ports = { up = "N", left = "V" } },
    { kind = "lapidus", cells = { { 7, 8 }, { 8, 8 } }, head = 2 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
