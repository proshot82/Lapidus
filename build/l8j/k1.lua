-- k1: «конвейер»: муфта на мыле; мыло — ногами (в слив), муфту везти на себе по коридору к мойке, поднять ногами; голова — в стояк
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "k1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "############",
    "#########.##",
    "########..##",
    "#..........#",
    "#..........#",
    "######.#####",
    "######~#####",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 10, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 9, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 6, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 6, 5 } },
    { kind = "lapidus", cells = { { 4, 5 }, { 4, 4 }, { 3, 4 } }, head = 3 },
  },
  ablations = { },
}
