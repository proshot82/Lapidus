-- build/l4v/controls.lua — контроли к абляциям (метрики без ходов).
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local MT = dofile("build/l4v/metrics.lua")
local def0 = dofile("build/l4d/k29.lua")
local function tagAt(d, tag, x, y) for _, o in ipairs(d.objects) do if o.tag == tag then o.at = { x, y } end end end
local function stubToWall(d)
  for i, o in ipairs(d.objects) do if o.kind == "stub" and o.at[1] == 5 then table.remove(d.objects, i) break end end
  d.grid[4] = d.grid[4]:sub(1, 4) .. "#" .. d.grid[4]:sub(6); return d
end
local C = {
  { "детали поменяны местами", function(d) tagAt(d, "cpl", 7, 3); tagAt(d, "nip", 4, 3); return d end },
  { "сборка заранее, отвод (5,4)→стена", function(d) stubToWall(d); tagAt(d, "cpl", 4, 3); tagAt(d, "nip", 4, 2); return d end },
  { "сборка заранее у шахты (8,5)/(8,6)", function(d) tagAt(d, "cpl", 8, 6); tagAt(d, "nip", 8, 5); return d end },
  { "муфта сразу в коридоре (3,6)", function(d) tagAt(d, "cpl", 3, 6); return d end },
  { "ниппель у левого края антресоли (3,3)", function(d) tagAt(d, "nip", 3, 3); return d end },
}
for _, c in ipairs(C) do
  local d = c[2](SV.deepcopy(def0)); d.ablations = nil
  print(string.format("%-38s %s", c[1], MT.fmt(MT.run(d))))
end
