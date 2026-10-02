-- кв. 9, кандидат e2 (= c7d + открыта (2,6)). Скелет «шахта»: колонка под потолком, стояк на дне той же шахты.
local okV, vis = pcall(dofile, "build/l9j/vis.lua")
local okA, A = pcall(dofile, "build/l9j/abl9.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "e2",
  length = { 3, 6 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "#########",
    "######.##",
    "#......##",
    "#..###.##",
    "#......##",
    "#..#.#.##",
    "#......##",
    "####~~.##",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 6, 5 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 5 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 }, { 3, 6 } }, head = 3 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
    { name = "тройник не поднимают", filter = okA and A.noLift("tee") or nil },
    { name = "заглушку не поднимают", filter = okA and A.noLift("plug") or nil },
    { name = "тройник сразу на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.at = { 7, 7 } end end end },
    { name = "заглушка сразу на тройнике", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "plug" then o.at = { 5, 5 } end end end },
    { name = "без лаза", mutate = function(d) d.grid[7] = "#....#.##" end },
  },
  texts = { request = "", hints = { "", "", "" } },
}
