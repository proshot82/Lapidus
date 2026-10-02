-- m1: два груза на спине; муфта — под стояк первой, иначе переходник прикипит к стояку
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B", "C" },
  id = 8, flat = 8, name = "m1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#############",
    "#############",
    "#######.#.###",
    "#...........#",
    "#..#.#......#",
    "######....###",
    "#############",
  },
  objects = {
    { kind = "source", at = { 8, 3 }, ports = { down = "N" } },
    { kind = "fixture", what = "sink", at = { 10, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 4, 4 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "adapter", tag = "B", at = { 6, 4 }, ports = { up = "V", down = "N" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 3 },
  },
  ablations = { },
}
