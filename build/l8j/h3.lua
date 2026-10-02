-- h3: затравка мутатора — ядро «башенка» слева (столбцы 1–5 заперты), правая часть свободна
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "h3",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "####.......#",
    "####.#.....#",
    "####.......#",
    "###........#",
    "##.........#",
    "###.###....#",
    "###~#####..#",
    "############",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 5, 5 }, ports = { left = "V", right = "V" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "porcelain", tag = "soap", at = { 5, 6 } },
    { kind = "lapidus", cells = { { 10, 8 }, { 10, 7 }, { 11, 7 } }, head = 3 },
  },
  ablations = { },
}
