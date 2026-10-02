-- c2: «лифт на стояке» с мылом-подпоркой: ниппель ловят на голову над шахтой, ноги идут к стояку по мылу,
-- мыло затем выбивают в слив. Поиск раскладки.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "c2",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "######.####",
    "######.####",
    "######....#",
    "######....#",
    "#####...###",
    "######.####",
    "######~####",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 6, 6 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 4 }, ports = { up = "N", down = "N" } },
    { kind = "porcelain", tag = "soap", at = { 8, 6 } },
    { kind = "lapidus", cells = { { 10, 5 }, { 9, 5 }, { 8, 5 } }, head = 1 },
  },
  ablations = { { name = "без ниппеля", remove = "nip" }, { name = "без мыла", remove = "soap" } },
}
