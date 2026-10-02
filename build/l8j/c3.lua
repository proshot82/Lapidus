-- c3: c2 без мыла, щедрый правый карман (поиск формы решения).
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 8, flat = 8, name = "c3",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "######.#####",
    "######.#####",
    "######.....#",
    "######...#.#",
    "#####......#",
    "######.#####",
    "######~#####",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 6, 6 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 11, 6 }, { 10, 6 } }, head = 2 },
  },
  ablations = { { name = "без ниппеля", remove = "nip" } },
}
