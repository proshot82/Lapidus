-- build/l3c/r2f.lua — черновик кандидата кв. 3. r2, стояк и мойка поменяны местами (наверх первыми идут ноги)
local STEP = { { 7,7 } }
local lost = dofile("build/l3c/vis.lua").make(STEP, false)
return {
  step = STEP, lost = lost, visibleLoss = lost,
  id = 3, flat = 3, name = "Мыло", length = { 2, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "####......#",
    "######.####",
    "##...#.####",
    "##.#.#.####",
    "#......####",
    "###....####",
    "#####~#####",
  },
  objects = {
    { at = { 10, 2 }, kind = "source", ports = { left = "V" } },
    { at = { 6, 2 }, kind = "fixture", ports = { right = "N" }, what = "sink" },
    { at = { 4,4 }, kind = "porcelain", tag = "soap" },
    { at = { 5,7 }, kind = "porcelain", tag = "soap" },
    { kind = "lapidus", cells = { { 4, 7 }, { 4, 6 }, { 3, 6 }, { 2, 6 } }, head = 4 },
  },
  ablations = { { name = "без фаянса", remove = "soap" } },
}
