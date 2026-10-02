-- k2: конвейер: переходник на мыле; мыло ногами в слив, переходник везти на спине, ногами поднять, голова в стояк
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "k2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "#########.##",
    "#######.#.##",
    "#..........#",
    "#..........#",
    "#####.######",
    "#####~######",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 10, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 8, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "adapter", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 3 },
  },
  ablations = { },
}
