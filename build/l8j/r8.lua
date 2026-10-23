-- r8: мыло толкается по яме к карману колонки, слив за карманом
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "r8",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "########.##",
    "######.#.##",
    "#........##",
    "#........##",
    "####......#",
    "#########~#",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 9, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 4, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 4, 5 } },
    { kind = "lapidus", cells = { { 3, 5 }, { 3, 4 } }, head = 2 },
  },
  ablations = { },
}
