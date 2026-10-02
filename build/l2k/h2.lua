local function wallHook(d) local k = {} for _, o in ipairs(d.objects) do if o.tag ~= "hook" then k[#k+1] = o end end d.objects = k
  local r = d.grid[5]; d.grid[5] = r:sub(1, 1) .. "#" .. r:sub(3) end
return {
  visibleLoss = dofile("build/l2k/vis.lua"),
  id = 2, flat = 2, name = "h2",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "##.....##",
    "#.......#",
    "#......##",
    "##.....##",
    "#.......#",
    "##~~~~~##",
  },
  objects = {
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "bath", at = { 3, 7 }, ports = { right = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 4, 3 }, { 3, 3 } }, head = 2 },
  },
  ablations = {
    { name = "без крюка (стена)", mutate = wallHook },
    { name = "без муфты", remove = "cpl" },
  },
}
