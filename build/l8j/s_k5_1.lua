-- мутатор: ходов 29, скрытых 2%, обезьяна 0.00%, глубина 0, двери 0/0, состояний 9337, выигрышных 1
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "k5",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#############",
    "##....##..#.#",
    "######.....##",
    "##..........#",
    "#..........##",
    "#.###..##..##",
    "#####.#..#.##",
    "#####~#######",
  },
  objects = {
    { kind = "source", at = { 10, 3 }, ports = { down = "N" } },
    { kind = "fixture", what = "sink", at = { 11, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 4, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 10, 2 } },
    { kind = "lapidus", cells = { { 4, 5 }, { 3, 5 }, { 3, 4 } }, head = 3 },
  },
  ablations = { { name = "без B", remove = "B" }, { name = "без soap", remove = "soap" }, },
}
