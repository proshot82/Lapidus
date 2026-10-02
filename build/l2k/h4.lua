local function wallHook(d) local k = {} for _, o in ipairs(d.objects) do if o.tag ~= "hook" then k[#k+1] = o end end d.objects = k
  local r = d.grid[6]; d.grid[6] = r:sub(1, 9) .. "#" .. r:sub(11) end
return {
  visibleLoss = dofile("build/l2k/vis.lua"),
  id = 2, flat = 2, name = "h4",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#####.##.##",
    "####.....##",
    "#####.....#",
    "#####....##",
    "#####..#.##",
    "#####~~#~##",
    "###########",
  },
  objects = {
    { kind = "stub", tag = "hook", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "source", at = { 5, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 7 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 7, 3 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 9, 3 }, { 8, 3 } }, head = 2 },
  },
  ablations = dofile("build/l2k/abl.lua")({ "hook" }, { "cpl" }),
}
