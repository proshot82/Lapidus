local function wallHook(d) local k = {} for _, o in ipairs(d.objects) do if o.tag ~= "hook" then k[#k+1] = o end end d.objects = k
  local r = d.grid[5]; d.grid[5] = r:sub(1, 1) .. "#" .. r:sub(3) end
return {
  visibleLoss = dofile("build/l2k/vis.lua"),
  id = 2, flat = 2, name = "h3",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  grid = {
    "########",
    "#......#",
    "#..##..#",
    "#......#",
    "#...#..#",
    "#......#",
    "#......#",
    "#~~~~~~#",
  },
  objects = {
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "toilet", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 4 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 5, 2 }, { 4, 2 } }, head = 2 },
  },
  ablations = dofile("build/l2k/abl.lua")({ "hook" }, { "cpl" }),
}
