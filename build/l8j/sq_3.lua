-- мутатор: ходов 28, скрытых 22%, обезьяна 0.00%, глубина 10, двери 1/1, состояний 9072, выигрышных 1, ширина 7
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "q1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "#.#.##...#",
    "###..#..##",
    "##.......#",
    "#.......##",
    "#..#....##",
    "##.#.#####",
    "####~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 4, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 4, 5 } },
    { kind = "lapidus", cells = { { 5, 3 }, { 4, 3 } }, head = 2 },
  },
  ablations = { { name = "без B", remove = "B" }, { name = "без soap", remove = "soap" }, },
}
