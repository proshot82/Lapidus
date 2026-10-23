local R = require("core.rules")
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
-- роль: пока угольник не прикручен, Лапидус не занимает угловую клетку колодца (3,5)
local function noCorner(lvl, st, ns)
  local q = tagOf(lvl, "elb")
  if ns.fixed[q] then return true end
  local c = R.idx(lvl, 3, 5)
  for _, b in ipairs(ns.body) do if b == c then return false end end
  return true
end
return {
  id = 78, flat = 6, name = "f5", length = { 4, 6 }, pressure = 0, tile = "mint",
  grid = {
    "#########",
    "##......#",
    "##.###.##",
    "##.....##",
    "#....####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 6, 4 }, { 7, 4 }, { 7, 3 }, { 7, 2 }, { 6, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без угольника", remove = "elb" },
    { name = "без муфты", remove = "cpl" },
    { name = "угольник сразу на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 3, 5 } end end end },
    { name = "колодец 2x2", mutate = function(d) d.grid[5] = "#...#####" end },
    { name = "колодец 2x2 сверху", mutate = function(d) d.grid[4] = "##.#...##" end },
    { name = "в углу колодца не стоят", filter = noCorner },
  },
}
