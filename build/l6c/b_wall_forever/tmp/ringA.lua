-- шаблон: кольцо вокруг блока со стояком и колонкой; обе двери — гнёзда деталей
local V = dofile("build/l6c/b_wall_forever/vis.lua")
return {
  length = { 3, 5 }, visibleLoss = V.vis, maxQ = 10,
  grid = {
    "#########",
    "#??#.#??#",
    "#.......#",
    "#.##.##.#",
    "#.......#",
    "##??.??##",
    "#########",
  },
  objects = {
    { kind = "source", at = { 5, 4 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "elbow", tag = "pt", at = { 7, 3 }, ports = { up = "N", left = "N" } },
    { kind = "fitting", what = "elbow", tag = "pb", at = { 7, 5 }, ports = { up = "V", left = "V" } },
  },
  starts = {
    { cells = { { 2, 3 }, { 2, 4 }, { 2, 5 }, { 3, 5 } }, head = 1 },
    { cells = { { 2, 3 }, { 2, 4 }, { 2, 5 }, { 3, 5 } }, head = 4 },
    { cells = { { 8, 3 }, { 8, 4 }, { 8, 5 } }, head = 1 },
    { cells = { { 8, 3 }, { 8, 4 }, { 8, 5 } }, head = 3 },
  },
}
