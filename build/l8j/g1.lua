-- g1: башня мыло/муфта/ниппель в нише; мыло — ногами в жёлоб, муфту — головой (прикипает на лету), ниппель на голове
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  id = 8, flat = 8, name = "g1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "####.#####",
    "####.#####",
    "####.....#",
    "###......#",
    "##.......#",
    "###.######",
    "###~######",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 5, 5 }, ports = { left = "V", right = "V" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "porcelain", tag = "soap", at = { 5, 6 } },
    { kind = "lapidus", cells = { { 7, 6 }, { 7, 5 }, { 8, 5 } }, head = 3 },
  },
  ablations = { },
}
