-- мутатор: ходов 34, скрытых 29%, обезьяна 0.00%, глубина 12, двери 1/1, состояний 8219, выигрышных 1, ширина 8
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "n13",
  length = { 3, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "##.####...##",
    "#.#.####..##",
    "#.#.......##",
    "#.........##",
    "#.#.#.....##",
    "############",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 10, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 9, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 4, 5 }, { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 4 },
  },
  ablations = { { name = "без B", remove = "B" }, { name = "без soap", remove = "soap" }, },
}
