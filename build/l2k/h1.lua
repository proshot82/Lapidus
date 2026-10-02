-- l2k/h1
return {
  visibleLoss = dofile("build/l2k/vis.lua"),
  id = 2, flat = 2, name = "h1",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 14, 24 }, states = 50000, dead = 25, fb = 1 },
  grid = {
    "########",
    "#......#",
    "#......#",
    "#....###",
    "#......#",
    "##.....#",
    "##.....#",
    "##~~~~~#",
    "########",
  },
  objects = {
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "source", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "fixture", what = "bath", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 3 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 3 }, { 7, 2 } }, head = 2 },
  },
  ablations = {
    { name = "без крюка (стена)", mutate = function(d) local k = {} for _, o in ipairs(d.objects) do if o.tag ~= "hook" then k[#k+1] = o end end d.objects = k; d.grid[5] = "##" .. d.grid[5]:sub(3) end },
    { name = "без муфты", remove = "cpl" },
  },
}
