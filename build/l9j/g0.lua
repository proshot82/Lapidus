-- кв. 9, раунд f, проба сети «заглушка снизу»: стояк В слева на полке, тройник входит в колонку сбоку, заглушка — через верх шахты.
local okV, vis = pcall(dofile, "build/l9j/vis9.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "g0", length = { 2, 6 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "######.###",
    "#......###",
    "#....#.###",
    "#.....####",
    "#......###",
    "#......###",
    "#......###",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 3, 8 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 6, 8 }, ports = { up = "N" } },
    { kind = "lapidus", cells = { { 4, 8 }, { 5, 8 } }, head = 2 },
  },
}
