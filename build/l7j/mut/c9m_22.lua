-- l7j c9m_22: мутатор build/l7j/mut.lua от build/l7j/mc9.lua (seed 22). Решение не пишется.
-- метрики: ходов 24, ширина 9, прогулка 7, скрытых 34%, обезьяна 0.00, глубина 28, двери 0/1, событий 5, сост 12173, конфиг 1, счёт -12.4
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "c9m_22",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "##########",
    "#........#",
    "#.#......#",
    "#......#.#",
    "#..#.....#",
    "#........#",
    "#........#",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 4, 4 }, ports = { right = "N", left = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 8, 8 }, ports = { up = "N", left = "V" } },
    { kind = "lapidus", cells = { { 3, 8 }, { 4, 8 } }, head = 2 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
  },
  texts = { request = "", hints = { "", "", "" } },
}
