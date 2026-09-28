-- build/l3c/b2.lua — черновик кандидата кв. 3. старт в центре, ноги под полкой справа
local STEP = { { 7,7 } }
local lost = dofile("build/l3c/vis.lua").make(STEP, false)
return {
  step = STEP, lost = lost, visibleLoss = lost,
  id = 3, flat = 3, name = "Мыло", length = { 2, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "####......#",
    "#####..####",
    "##.....####",
    "##.#...####",
    "#......####",
    "###....####",
    "#####~#####",
  },
  objects = {
    { at = { 6, 2 }, kind = "source", ports = { right = "V" } },
    { at = { 10, 2 }, kind = "fixture", ports = { left = "N" }, what = "sink" },
    { at = { 4,4 }, kind = "porcelain", tag = "soap" },
    { at = { 5,7 }, kind = "porcelain", tag = "soap" },
    { kind = "lapidus", cells = { { 5, 5 }, { 6, 5 }, { 6, 6 }, { 6, 7 } }, head = 4 },
  },
  ablations = { { name = "без фаянса", remove = "soap" } },
}
