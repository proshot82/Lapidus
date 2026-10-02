-- c1: «лифт на стояке»: муфту/ниппель надо поймать на голову над шахтой со сливом, ногами дотянуться до стояка,
-- не сдвинув голову, и поднять ниппель к мойке. Поиск раскладки.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 8, flat = 8, name = "c1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "######.###",
    "######.###",
    "##.....###",
    "###....###",
    "###.....##",
    "######.###",
    "######~###",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 8, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 3, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 6 }, { 5, 6 } }, head = 2 },
  },
  ablations = { { name = "без ниппеля", remove = "nip" } },
}
