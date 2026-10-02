-- мутатор: ходов 19, скрытых 14%, обезьяна 0.11%, глубина 0, двери 0/0, состояний 3725, выигрышных 4
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "g2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "####..#.##.#",
    "####.#..##.#",
    "####.#....##",
    "###....#..##",
    "##......#..#",
    "###.#..#...#",
    "###~###..#.#",
    "############",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 8, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 5, 5 }, ports = { right = "V", left = "V" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "porcelain", tag = "soap", at = { 5, 6 } },
    { kind = "lapidus", cells = { { 9, 8 }, { 9, 7 }, { 10, 7 } }, head = 3 },
  },
  ablations = { { name = "без B", remove = "B" }, { name = "без A", remove = "A" }, { name = "без soap", remove = "soap" }, },
}
