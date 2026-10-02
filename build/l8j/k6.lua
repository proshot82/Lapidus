-- k6: конвейер; у мойки — слив во всю глубину: поднять переходник можно только повиснув головой на стояке
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "k6",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#############",
    "#############",
    "#########..##",
    "#..........##",
    "#..........##",
    "#####.###..##",
    "#####~###~~##",
  },
  objects = {
    { kind = "source", at = { 10, 3 }, ports = { down = "N" } },
    { kind = "fixture", what = "sink", at = { 11, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "adapter", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 3 },
  },
  ablations = { },
}
