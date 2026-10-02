-- l7j c9m_21: мутатор build/l7j/mut.lua от build/l7j/mc9.lua (seed 21). Решение не пишется.
-- метрики: ходов 25, ширина 2, прогулка 5, скрытых 59%, обезьяна 0.00, глубина 0, двери 0/0, событий 7, сост 16390, конфиг 1, счёт -1.4
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "c9m_21",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "#........#",
    "#......#.#",
    "#........#",
    "#..#..#..#",
    "#........#",
    "#........#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 8, 8 }, ports = { right = "N", left = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 4 }, ports = { up = "N", left = "V" } },
    { kind = "lapidus", cells = { { 5, 8 }, { 6, 8 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
